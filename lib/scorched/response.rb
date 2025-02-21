module Scorched
  class Response < Rack::Response
    # Merges another response object (or response array) into self in order to preserve references to this response
    # object.
    def merge!(response)
      return self if response == self
      if Rack::Response === response
        response = [response.status, response.headers, response]
      end
      self.status, self.body = response[0], response[2]
      self.headers.merge!(response[1])
      self
    end

    # Automatically wraps the assigned value in an array if it doesn't respond to ``each``.
    # Also filters out non-true values and empty strings.
    def body=(value)
      value = [] if !value || value == ''
      super(value.respond_to?(:each) ? value : [value.to_s])
    end

    # Override finish to avoid using BodyProxy
    def finish(*args, &block)
      self['Content-Type'] ||= 'text/html;charset=utf-8'
      @block = block if block
      if [204, 205, 304].include?(status.to_i)
        delete_header "Content-Type"
        delete_header "Content-Length"
        close
        [status.to_i, headers, []]
      else
        [status.to_i, headers, body]
      end
    end

    attr_accessor :halted

    alias :to_a :finish
    alias :to_ary :finish
  end
end
