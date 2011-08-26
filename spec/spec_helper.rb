require 'active_record'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'data_resurrection'))
Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'config', '*.rb'))).each do |f|
  require f
end

ActiveRecord::Migration.verbose = false

