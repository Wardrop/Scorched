module Scorched
  class Options < Hash
    # Redefine all methods as delegates of the underlying local hash.
    extend DynamicDelegate
    delegate 'to_hash', *Hash.instance_methods(false)
    
    def <<(hash)
      raise ArgumentErrorm "Argument must be a hash" unless Hash === hash
      local_hash.clear.merge!(hash)
    end
    
    def []=(key, value)
      local_hash[key] = value
    end
    
    def local_hash
      @hash ||= {}
    end
  end
  
  class << self
    def Options(accessor_name)
      m = Module.new
      m.class_eval <<-MOD
        class << self
          def included(klass)
            klass.extend(ClassMethods)
          end
        end

        module ClassMethods
          def #{accessor_name}(inherit = true)
            @#{accessor_name} || begin
              @#{accessor_name} = Options.new
              parent = superclass.#{accessor_name} if superclass.respond_to?(:#{accessor_name}) && Scorched::Options === superclass.#{accessor_name}
              @#{accessor_name}.define_singleton_method(:to_hash) do
                parent ? parent.to_hash.merge(local_hash) : local_hash.clone
              end
              @#{accessor_name}
            end
          end
        end

        def #{accessor_name}(*args)
          self.class.#{accessor_name}(*args)
        end
      MOD
      m
    end
  end
end


# class Base
#   include Scorched::Options('config')
# end
# 
# class Child < Base
# end
# 
# Base.config[:woof] = 'dog'
# p Base.config[:woof]
# p Child.config[:woof]
# Child.config[:woof] = 'horse'
# p Base.config[:woof]
# p Child.config[:woof]