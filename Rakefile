require 'fileutils'
require 'rspec'
require 'rspec/core/rake_task'
require 'rake/clean'
require './lib/scorched/version'

CLEAN.include "pkg"

task :default => :spec
task :test => :spec

RSpec::Core::RakeTask.new(:spec)

task :release => [:spec, :'gem:install', :commit_version, :'gem:release', :clean]

task :commit_version do
  sh "git commit --allow-empty -a -m 'v#{Scorched::VERSION} release.'  &&
    git tag -a #{Scorched::VERSION} -m 'v#{Scorched::VERSION} release.'  &&
    git push &&
    git push --tags"
end

namespace :gem do
  require "bundler/gem_tasks"
end