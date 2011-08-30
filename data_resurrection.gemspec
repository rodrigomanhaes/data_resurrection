# encoding: utf-8

Gem::Specification.new do |s|
  s.name = 'data_resurrection'
  s.version = '0.1.1'
  s.date = %q{2011-08-30}
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.author = 'Rodrigo Manhães'
  s.description = 'Converts DBF to modern formats.'
  s.email = 'rmanhaes@gmail.com'
  s.homepage = 'https://github.com/rodrigomanhaes/data_resurrection'
  s.summary = 'Bring your data, buried in decrepit formats, back to life! Convert data from old formats to modern ones. Currently supports DBF.'

  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']

  s.files = Dir.glob('lib/**/*.rb') + %w(README.rdoc LICENSE.txt lib/data_resurrection/reserved_words)
  s.add_dependency('activerecord', '~> 3.0.0')
  s.add_dependency('dbf', '~> 1.5.0')
  s.add_development_dependency('sqlite3', '~> 1.3.0')
  s.add_development_dependency('rspec', '~> 2.6.0')
end

