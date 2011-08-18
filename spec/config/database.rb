require 'sqlite3'

def db_file
  File.expand_path(File.join(File.dirname(__FILE__), 'db.sqlite3'))
end

def create_test_database
  File.unlink(db_file) if File.exist?(db_file)
  SQLite3::Database.new(db_file)
end

def test_database_settings
  { 'adapter' => 'sqlite3',
    'database' => db_file,
    'pool' => 5,
    'timeout' => 5000 }
end

