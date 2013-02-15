module Scorched
  class << self
    def Collection(accessor_name)
      accessor_name = accessor_name.to_s
      m = Module.new
      m.class_eval <<-MOD
        class << self
          def included(klass)
            klass.extend(ClassMethods)
          end
        end

        module ClassMethods
          def #{accessor_name}(inherit = true)
            @#{accessor_name} ||= []
            if inherit
              if superclass.respond_to?(:#{accessor_name}) && superclass.respond_to?(:#{accessor_name}=)
                retval = superclass.#{accessor_name} + (@#{accessor_name})
                _collection = @#{accessor_name}
                retval.define_singleton_method(:<<) do |value|
                  _collection << value
                  super(value)
                end
                return retval
              end
            end
            @#{accessor_name}
          end

          def #{accessor_name}=(array)
            @#{accessor_name} = array
          end
        end

        def #{accessor_name}(*args)
          self.class.#{accessor_name}(*args)
        end

        def #{accessor_name}=(arg)
          self.class.#{accessor_name} = arg
        end
      MOD
      
      m
    end
  end
end