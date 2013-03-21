module Scorched
  class Options < Hash
    # Redefine all methods as delegates of the underlying local hash.
    extend DynamicDelegate
    alias_each(Hash.instance_methods(false)) { |m| "_#{m}" }
    delegate 'to_hash', *Hash.instance_methods(false).reject { |m|
      [:[]=, :clear, :delete, :delete_if, :merge!, :replace, :shift, :store].include? m
    }
    
    alias_method :<<, :_merge!
    
    # sets parent Options object and returns self
    def parent!(parent)
      @parent = parent
      self
    end
    
    def to_hash(inherit = true)
      (inherit && Hash === @parent) ? @parent.to_hash.merge(self) : {}.merge(self)
    end
    
    def inspect
      "#<#{self.class}: local#{_inspect}, merged#{to_hash.inspect}>"
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
          def #{accessor_name}
            @#{accessor_name} || begin
              parent = superclass.#{accessor_name} if superclass.respond_to?(:#{accessor_name}) && Scorched::Options === superclass.#{accessor_name}
              @#{accessor_name} = Options.new.parent!(parent)
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

