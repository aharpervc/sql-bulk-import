require 'benchmark'

RSpec.describe 'Benchmark Tests', :benchmark do
  it 'benchmarks importing a CSV file with a million rows' do
    import_csv_file_path = generate_csv_file(10, 1_000_000)

    elapsed_time = Benchmark.realtime do
      SQLBulkImport.import_csv_file import_csv_file_path, true
    end

    puts "Importing a CSV with a million rows took #{elapsed_time.round(2)} seconds (#{(1_000_000 / elapsed_time).round(2)} rows/sec)"
  ensure
    FileUtils.rm_f import_csv_file_path
  end
end
