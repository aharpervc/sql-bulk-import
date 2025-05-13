# frozen_string_literal: true

require 'rspec'
require 'fileutils'
require 'csv'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  # config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end

def export_csv_file_path(import_csv_file_path)
  basename = File.basename import_csv_file_path
  "./spec/fixtures/actual/#{basename}"
end

def expected_csv_file_path(import_csv_file_name)
  "./spec/fixtures/expected/#{import_csv_file_name}"
end

def generate_csv_file(column_count, row_count)
  file_path = "./spec/fixtures/generated/c#{column_count}_r#{row_count}.csv"
  FileUtils.mkdir_p(File.dirname(file_path))

  CSV.open(file_path, 'w') do |csv|
    # Write headers
    headers = (1..column_count).map { |i| "col_#{i}" }
    csv << headers

    row_count.times do
      row = Array.new(column_count) { |i| i.even? ? rand(1..1000) : ('a'..'z').to_a.sample(5).join }
      csv << row
    end
  end

  file_path
end
