module Scorched
  # Unlike most delegator's that delegate to an object, this delegator delegates to a runtime expression, and so the
  # target object can be dynamic.
  module DynamicDelegate
    def delegate(target_literal, *methods)
      methods.each do |method|
        method = method.to_sym
        class_eval <<-CODE
          def #{method}(*args, &block)
            #{target_literal}.__send__(#{method.inspect}, *args, &block)
          end
        CODE
      end
    end
    
    def alias_each(methods)
      methods.each do |m|
        alias_method yield(m), m
      end
    end
  end
end