require 'set'

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
          def #{accessor_name}(inherit = false)
            @#{accessor_name} ||= Set.new
            if inherit
              
              if superclass.respond_to?(:#{accessor_name}) && superclass.respond_to?(:#{accessor_name}=)
                return superclass.#{accessor_name}(true) + @#{accessor_name}
              end
            end
            @#{accessor_name}
          end

          def #{accessor_name}=(set)
            @#{accessor_name} = (Set === set) ? set : set.to_set
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