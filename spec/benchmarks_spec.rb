require 'benchmark'

def spinner
  return if ENV['CI']

  Thread.new do
    chars = ['|', '/', '-', '\\']
    i = 0
    loop do
      print "\r#{chars[i]} "
      $stdout.flush
      sleep 0.05
      i = (i + 1) % chars.length
    end
  end
end
RSpec.describe 'Benchmark Tests', :benchmark do

  it 'benchmarks importing a CSV file with a million rows' do
    spinner

    puts "Generating CSV file..."
    import_csv_file_path = generate_csv_file(10, 1_000_000)

    puts "Starting import..."
    elapsed_time = Benchmark.realtime do
      t = Thread.new do
        SQLBulkImport.import_csv_file import_csv_file_path, true
      end
      t.join
    end

    puts "Done"
    puts "Importing a CSV with a million rows took #{elapsed_time.round(2)} seconds (#{(1_000_000 / elapsed_time).round(2)} rows/sec)"
  ensure
    FileUtils.rm_f import_csv_file_path
  end
end
