require 'rack'
require 'rack/protection'
require 'rack/accept'

require_relative 'scorched/options'
require_relative 'scorched/controller_helpers'
require_relative 'scorched/controller'
require_relative 'scorched/error'
require_relative 'scorched/request'
require_relative 'scorched/response'

Scorched::VERSION = '0.1'