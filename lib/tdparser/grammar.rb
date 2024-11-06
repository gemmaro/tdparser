module TDParser
  class Grammar
    include TDParser

    def define(&block)
      instance_eval {
        begin
          alias method_missing g_method_missing
          block.call(self)
        end
      }
    end

    def g_method_missing(sym, *args) # :nodoc:
      arg0 = args[0]
      sym = sym.to_s
      if sym[-1, 1] == "="
        name = sym[0..-2]
        case arg0
        when Parser
          self.class.instance_eval {
            method_defined?(name) or
              define_method(name) { arg0 }
          }
        else
          t = token(arg0)
          self.class.instance_eval {
            method_defined?(name) or
            define_method(name) { t }
          }
        end
      elsif args.size == 0
        rule(sym)
      else
        raise(NoMethodError, "undefined method `#{sym}' for #{self.inspect}")
      end
    end

    alias method_missing g_method_missing # :nodoc:
  end
end
