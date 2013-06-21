require 'rspec'
require 'rspec/core/rake_task'
require 'rake/clean'

CLEAN.include "pkg"

task :default => :spec
task :test => :spec

RSpec::Core::RakeTask.new(:spec)

task :release => [:spec, :'gem:install'] do
  puts 'Work in progress'
  Rake::Task['clean'].invoke
end

namespace :gem do
  require "bundler/gem_tasks"
end