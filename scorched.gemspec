$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'scorched' # Load scorched to inspect it for information, such as version.

Gem::Specification.new 'scorched', Scorched::VERSION do |s|
  s.description       = "Scorched description"
  s.summary           = "Scorched summary"
  s.authors           = ["Tom Wardrop"]
  s.email             = "tom@tomwardrop.com"
  s.homepage          = "http://tomwardrop.com"
  s.files             = Dir.glob(`git ls-files`.split("\n") - %w[.gitignore])
  s.test_files        = Dir.glob('spec/**/*_spec.rb')
  s.rdoc_options      = %w[--line-numbers --inline-source --title Scorched --encoding=UTF-8]

  s.add_dependency 'rack',            '~> 1.4'
  s.add_dependency 'rack-protection', '~> 1.2'
  s.add_dependency 'rack-accept', '~> 0.4.5'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'rspec',     '~> 2.9'
end