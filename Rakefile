require 'fileutils'
require 'rspec'
require 'rspec/core/rake_task'
require 'rake/clean'
require './lib/scorched/version'

CLEAN.include "pkg"

task :default => :spec
task :test => :spec

RSpec::Core::RakeTask.new(:spec)

desc 'Releases a new version of Scorched.'
task :release => [:prerelease, :spec, :'gem:install', :commit_version, :'gem:release', :clean]

desc 'Commits and tags git repository as new version, pushing up to github'
task :commit_version do
  sh "git commit --allow-empty -a -m 'v#{Scorched::VERSION} release.'  &&
    git tag -a #{Scorched::VERSION} -m 'v#{Scorched::VERSION} release.'  &&
    git push &&
    git push --tags"
end

desc 'Displays a pre-release message, requiring user input'
task :prerelease do
  puts <<-MSG

About to release Scorched v#{Scorched::VERSION}. Please ensure CHANGES log is up-to-date, all relevant documentation is updated, changes on Github master repository have been pulled and merged, and that any new files not under version control have been added/staged. Press any key to continue...
  MSG
  STDIN.gets
end

namespace :gem do
  require "bundler/gem_tasks"
end