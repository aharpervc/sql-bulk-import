# frozen_string_literal: true

require_relative '../lib/sql-bulk-import'
require 'spec_helper'

RSpec.describe SQLBulkImport do
  it 'has a version number' do
    expect(SQLBulkImport::VERSION).not_to be_nil
  end

  it 'imports/exports to/from a database table' do
    Dir.glob('./spec/fixtures/round_trip/*.csv').each do |import_csv_file_path|
      export_csv_file_path = export_csv_file_path import_csv_file_path
      FileUtils.rm_f export_csv_file_path

      import_table_name = described_class.import_csv_file import_csv_file_path, true
      expect(import_table_name).to eq File.basename(import_csv_file_path, '.csv')

      described_class.export_csv_file import_table_name, export_csv_file_path

      expect(File.exist?(export_csv_file_path)).to be true
      expect(File.read(import_csv_file_path)).to eq File.read(export_csv_file_path)
    ensure
      File.unlink export_csv_file_path
    end
  end

  it 'imports/export CSV files safely' do
    Dir.glob('./spec/fixtures/*.csv').each do |import_csv_file_path|
      expected_csv_file_path = expected_csv_file_path csv_file_name

      export_csv_file_path = export_csv_file_path import_csv_file_path
      FileUtils.rm_f export_csv_file_path

      import_table_name = described_class.import_csv_file import_csv_file_path, true
      described_class.export_csv_file import_table_name, export_csv_file_path

      expect(File.exist?(export_csv_file_path)).to be true
      expect(File.read(export_csv_file_path)).to eq(File.read(expected_csv_file_path))
    ensure
      File.unlink export_csv_file_path
    end
  end

  it 'raises an error when the import file is empty' do
    expect do
      described_class.import_csv_file './spec/fixtures/empty_file.csv', false
    end.to raise_error(RuntimeError, /No such file or directory/)
  end

  it "raises an error when the import file doesn't exist" do
    expect do
      described_class.import_csv_file './spec/fixtures/does_not_exist.csv', false
    end.to raise_error(RuntimeError, /No such file or directory/)
  end

  it "raises an error when the database table doesn't exist" do
    expect do
      described_class.export_csv_file 'does_not_exist', './spec/fixtures/actual/does_not_exist.csv'
    end.to raise_error(RuntimeError, /Invalid object name 'does_not_exist'/)
  end

  it 'raises an error when importing to a database table that already exists (`reset = false`)' do
    import_csv_file_path = './spec/fixtures/round_trip/normal.csv'
    described_class.import_csv_file import_csv_file_path, true

    expect do
      described_class.import_csv_file import_csv_file_path, false
    end.to raise_error(RuntimeError, /There is already an object named 'normal' in the database/)
  end

  it 'imports to a database table that already exists (`reset = true`)' do
    import_csv_file_path = './spec/fixtures/round_trip/normal.csv'
    described_class.import_csv_file import_csv_file_path, true

    expect do
      described_class.import_csv_file import_csv_file_path, true
    end.not_to raise_error
  end
end
