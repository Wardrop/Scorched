module Scorched
  class Response < Rack::Response
    # Merges another response object (or response array) into self in order to preserve references to this response
    # object.
    def merge!(response)
      return self if response == self
      if Rack::Response === response
        response.finish
        self.status = response.status
        self.header.merge!(response.header)
        self.body = []
        response.each { |v| self.body << v }
      else
        self.status, @header, self.body = response
      end
    end
  end
end