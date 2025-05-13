# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'fileutils'

PLATFORMS = [
  'x86_64-linux',
  'aarch64-linux',
  'x86_64-darwin',
  'arm64-darwin',
  # "x64-mingw-ucrt",
  'x64-mingw32',
].freeze

gemspec = Bundler.load_gemspec('sql-bulk-import.gemspec')
Rake::ExtensionTask.new('sql_bulk_import_rs', gemspec) do |ext|
  ext.lib_dir = 'lib/sql-bulk-import'
  ext.cross_compile = true
  ext.cross_platform = PLATFORMS
  ext.cross_compiling do |spec|
    spec.dependencies.reject! { |dep| dep.name == 'rb_sys' }
    spec.files.reject! { |file| File.fnmatch?('ext/*', file, File::FNM_EXTGLOB) }
    spec.post_install_message = 'You installed the binary version of this gem!'
  end
end
