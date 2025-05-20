use std::{collections::HashSet, error::Error, path::Path};

use csv::Reader;
use magnus::{define_module, function, prelude::*};
use tiberius::{Client, ColumnData, Config, TokenRow};
use tokio::net::TcpStream;
use tokio_util::compat::Compat;

const DEFAULT_PORT: &str = "1433";

async fn create_database_connection() -> Result<Client<Compat<TcpStream>>, Box<dyn Error>> {
    let mut config = Config::new();
    config.host("localhost");
    config.port(DEFAULT_PORT.parse::<u16>()?);
    config.database("test_database");
    config.authentication(tiberius::AuthMethod::sql_server("sa", "Testing123@@"));
    config.encryption(tiberius::EncryptionLevel::On);
    config.trust_cert();

    let tcp = TcpStream::connect(config.get_addr()).await?;
    tcp.set_nodelay(true)?;

    let client = Client::connect(config, <TcpStream as tokio_util::compat::TokioAsyncWriteCompatExt>::compat_write(tcp)).await?;
    Ok(client)
}

#[tokio::main]
async fn import_csv_file(path: String, reset_table: bool) -> Result<String, Box<dyn Error>> {
    let file_stem = Path::new(&path)
        .file_stem()
        .and_then(|name| name.to_str())
        .unwrap();
    let safe_table_name = replace_invalid_chars(file_stem);

    let mut csv_reader = Reader::from_path(&path)?;
    let mut client = create_database_connection().await?;

    if reset_table {
        let drop_table_statement = format!("drop table if exists [{}]", safe_table_name);
        client.simple_query(&drop_table_statement).await?;
    }

    let create_table_statement = format!(
        "create table [{}] ({})",
        safe_table_name,
        column_definition_sql(csv_reader.headers()?)?.join(", ")
    );
    client.simple_query(&create_table_statement).await?;

    let mut bulk_insert = client.bulk_insert(&safe_table_name).await?;
    for result in csv_reader.records() {
        let record = result?;
        let mut token_row = TokenRow::new();
        for field in &record {
            if field.is_empty() {
                token_row.push(ColumnData::String(None));
                continue;
            }
            token_row.push(ColumnData::String(Some(field.to_string().into())));
        }
        bulk_insert.send(token_row).await?;
    }

    bulk_insert.finalize().await?;

    Ok(safe_table_name)
}

#[tokio::main]
async fn export_csv_file(table_name: String, file_path: String) -> Result<(), Box<dyn Error>> {
    if table_name.is_empty() {
        return Err("Missing required parameter value: table_name".into());
    }
    if file_path.is_empty() {
        return Err("Missing required parameter value: file_path".into());
    }

    let mut client = create_database_connection().await?;

    let safe_table_name = table_name.replace("]", "]]").replace("[", "[[");
    let mut query_results = client.simple_query(&format!("select * from [{}]", safe_table_name)).await?;

    let columns = query_results.columns().await?.ok_or("Failed to retrieve columns from the query result")?;
    let csv_headers: Vec<String> = columns.iter().map(|col| col.name().to_string()).collect();

    let mut writer = csv::Writer::from_path(file_path)?;
    writer.write_record(&csv_headers)?;

    let mut row_stream = query_results.into_row_stream();
    while let Some(row) = futures_util::stream::TryStreamExt::try_next(&mut row_stream).await? {
        let record: Vec<String> = row
            .into_iter()
            .map(|col| match col {
                ColumnData::String(Some(value)) => value.to_string(),
                ColumnData::String(None) => String::new(),
                _ => String::new(),
            })
            .collect();
        writer.write_record(&record)?;
    }

    writer.flush()?;
    Ok(())
}

fn column_definition_sql(headers: &csv::StringRecord) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    if headers.is_empty() {
        return Err("No column names found in CSV file".into());
    }

    let mut column_names = HashSet::new();
    let mut column_definitions = vec![];

    for (i, header) in headers.iter().enumerate() {
        let safe_header_name = replace_invalid_chars(header);
        let safe_header_name = if safe_header_name.is_empty() {
            format!("column_{}", i + 1)
        } else {
            safe_header_name.clone()
        };

        let mut unique_column_name = safe_header_name.clone();
        let mut counter = i;
        while !column_names.insert(unique_column_name.clone()) {
            unique_column_name = format!("{}_{}", safe_header_name, counter + 1);
            counter += 1;
        }

        column_definitions.push(format!("[{}] nvarchar(max) null", unique_column_name));
    }

    Ok(column_definitions)
}

fn replace_invalid_chars(name: &str) -> String {
    // todo: check for reserved keywords
    let safe_name = name.trim()
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric()  {
                c
            } else {
                '_'
            }
        })
        .collect::<String>();

    // if the first character is a number, prefix with an underscore
    if safe_name.chars().next().is_some_and(|c| c.is_numeric()) {
        format!("_{}", safe_name)
    } else {
        safe_name.to_string()
    }
}


fn ruby_import_csv_file(path: String, reset_table: bool) -> Result<String, magnus::Error> {
    import_csv_file(path, reset_table).map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))
}

fn ruby_export_csv_file(table_name: String, file_path: String) -> Result<(), magnus::Error> {
    export_csv_file(table_name, file_path).map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))
}

#[magnus::init]
fn init() -> Result<(), magnus::Error> {
    let module = define_module("SQLBulkImport")?;
    module.define_singleton_method("import_csv_file", function!(ruby_import_csv_file, 2))?;
    module.define_singleton_method("export_csv_file", function!(ruby_export_csv_file, 2))?;
    Ok(())
}
