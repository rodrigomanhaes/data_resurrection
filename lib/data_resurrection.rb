data_resurrection_folder = File.join(File.dirname(__FILE__), 'data_resurrection', '*')
Dir.glob(data_resurrection_folder).each {|f| require f }

