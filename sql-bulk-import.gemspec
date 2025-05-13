# frozen_string_literal: true

require_relative 'lib/sql_bulk_import/version'

Gem::Specification.new do |s|
  s.name = 'sql-bulk-import'
  s.version = SQLBulkImport::VERSION
  s.summary = 'CSV to SQL Server using bulk import'
  s.authors = ['Veracross']
  s.homepage = 'https://github.com/aharpervc/sql-bulk-import'
  s.license = 'private'
  s.files = Dir['lib/**/*', 'ext/**/*', 'extconf.rb']
  s.require_paths = ['lib']
  s.extensions = ['ext/sql_bulk_import_rs/extconf.rb']
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['allowed_push_host'] = 'http://localhost'
  s.required_ruby_version = '>= 2.7.8'

  s.add_dependency 'rb_sys', '~> 0.9'
end
