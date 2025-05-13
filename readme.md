```
   _____  ____  _      ____        _ _    _____                            _
  / ____|/ __ \| |    |  _ \      | | |  |_   _|                          | |
 | (___ | |  | | |    | |_) |_   _| | | __ | |  _ __ ___  _ __   ___  _ __| |_
  \___ \| |  | | |    |  _ <| | | | | |/ / | | | '_ ` _ \| '_ \ / _ \| '__| __|
  ____) | |__| | |____| |_) | |_| | |   < _| |_| | | | | | |_) | (_) | |  | |_
 |_____/ \___\_\______|____/ \__,_|_|_|\_\_____|_| |_| |_| .__/ \___/|_|   \__|
                                                         | |
                                                         |_|
```

A Ruby gem to bulk import CSV files to database tables

### Usage

### Development

Prerequisites:

1. [Ruby](https://github.com/rbenv/rbenv?tab=readme-ov-file#installation)
2. [Rust](https://rustup.rs)
3. [Docker](https://docs.docker.com/desktop)

Run these commands to get started:

1. `git clone git@github.com:aharpervc/sql-bulk-import.git`
2. `cd sql-bulk-import`
3. `docker compose up -d` & wait for the test container to become healthy
4. `./setup-database.sh` to create the test database
5. `bundle exec rake compile` to compile the Rust code for your current system
6. `bundle exec rspec`

If the tests run successfully, your environment is prepared for development.

Making changes inner Rust library needs to be compiled prior to running the Ruby code, including tests.

### Testing

- `bundle exec rspec` for normal tests
- `bundle exec rspec --tag benchmark` for benchmarks

There's two forms of automatic tests:

1. Files added to the `spec/fixtures/round_trip` folder will be tested automatically by importing them, then exporting that database table back to a CSV file and confirming the exported file matches the original import file.
2. Files added to the `spec/fixtures/import` folder will be tested automatically by importing them, then exporting that database table back to a CSV file and confirming the exported file matches a second fixture file of the same name in `spec/fixtures/expected`.

### Publishing a release

1. `bundle exec rake-compiler-dock rake cross native gem`
