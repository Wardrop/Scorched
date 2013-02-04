module Scorched
  
  class << self
    def Options(accessor_name)
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
            @#{accessor_name} ||= {}
            if inherit
              if superclass.respond_to?(:#{accessor_name}) && superclass.respond_to?(:#{accessor_name}=)
                retval = superclass.#{accessor_name}.merge(@#{accessor_name})
                _options = @#{accessor_name}
                retval.define_singleton_method(:[]=) do |key, value|
                  _options[key] = value
                  super(key, value)
                end
                return retval
              end
            end
            @#{accessor_name}
          end

          def #{accessor_name}=(hash)
            @#{accessor_name} = hash
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
  
  Options = Options('options')
  
end