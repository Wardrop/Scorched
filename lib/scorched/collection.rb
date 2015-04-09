module Scorched
  class Collection < Set
    # Redefine all methods as delegates of the underlying local set.
    extend DynamicDelegate
    alias_each(Set.instance_methods(false)) { |m| "_#{m}" }
    delegate 'to_set', *Set.instance_methods(false).reject { |m|
      [:<<, :add, :add?, :clear, :delete, :delete?, :delete_if, :merge, :replace, :subtract].include? m
    }
    
    # If true, parent values are appended to self. The default behavior is to append self to the parent values.
    attr_accessor :append_parent
    
    # Sets parent Collection object and returns self
    def parent!(parent)
      @parent = parent
      self
    end
    
    def to_set(inherit = true)
      if inherit && (Set === @parent || Array === @parent)
        if append_parent
          Set.new.merge(self._to_a).merge(@parent.to_set)
        else
          Set.new.merge(@parent.to_set).merge(self._to_a)
        end
      else
        Set.new.merge(self._to_a)
      end
    end
    
    def to_a(inherit = true)
      to_set(inherit).to_a
    end
    
    def inspect
      "#<#{self.class}(#{super}, #{to_set.inspect})>"
    end
  end
  
  class << self
    def Collection(accessor_name, append_parent = false)
      m = Module.new
      m.class_eval <<-MOD
        class << self
          def included(klass)
            klass.extend(ClassMethods)
          end
        end

        module ClassMethods
          def #{accessor_name}
            @#{accessor_name} || begin
              parent = superclass.#{accessor_name} if superclass.respond_to?(:#{accessor_name}) && Scorched::Collection === superclass.#{accessor_name}
              @#{accessor_name} = Collection.new.parent!(parent)
              @#{accessor_name}.append_parent = #{append_parent.inspect}
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
