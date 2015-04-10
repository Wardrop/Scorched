require 'ruby-prof'
require 'rack/mock'
require 'allocation_stats'
require 'scorched'
require 'sinatra/base'

scorched = Class.new(Scorched::Controller) do
  get '/' do
    'Hello world'
  end
end

sinatra = Class.new(Sinatra::Base) do
  get '/' do
    'Hello world'
  end
end



scorched_stats = AllocationStats.new(burn: 5).trace do
  scorched.call(Rack::MockRequest.env_for('/'))
end

sinatra_stats = AllocationStats.new(burn: 5).trace do
  sinatra.call(Rack::MockRequest.env_for('/'))
end

puts "Scorched Allocations: #{scorched_stats.allocations.all.size}"
puts "Scorched Memsize: #{scorched_stats.allocations.bytes.to_a.inject(&:+)}"

puts "Sinatra Allocations: #{sinatra_stats.allocations.all.size}"
puts "Sinatra Memsize: #{sinatra_stats.allocations.bytes.to_a.inject(&:+)}"
