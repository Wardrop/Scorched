ENV['RACK_ENV'] ||= 'development'

# Gems
require 'rack'
require 'rack/accept'
require 'tilt'

# Stdlib
require 'set'
require 'logger'

require_relative 'scorched/static'
require_relative 'scorched/dynamic_delegate'
require_relative 'scorched/options'
require_relative 'scorched/collection'
require_relative 'scorched/match'
require_relative 'scorched/controller'
require_relative 'scorched/error'
require_relative 'scorched/request'
require_relative 'scorched/response'
require_relative 'scorched/version'