def change_reserved_words(*reserved)
  File.open(save_file, 'w+') {|f| f.write File.read(original_file) }
  File.open(original_file, 'w+') {|f| f.write(reserved.join("\n")) }
end

def restore_reserved_words
  File.open(original_file, 'w+') {|f| f.write File.read(save_file) }
  File.unlink(save_file)
end

def original_file
  File.expand_path(File.join(File.dirname(__FILE__),
    '..', '..', 'lib', 'data_resurrection', 'reserved_words'))
end

def save_file
  File.expand_path(File.join(File.dirname(__FILE__), 'reserved_words'))
end

