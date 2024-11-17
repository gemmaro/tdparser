module TDParser
  class Grammar # :nodoc:
    include TDParser

    alias define instance_eval

    def method_missing(sym, *args)
      if sym[-1, 1] == '='
        parser, = args
        name = sym[0..-2]
        parser.is_a?(Parser) or parser = token(parser)
        self.class.instance_eval do
          instance_methods.include?(name.intern) or
            define_method(name) { parser }
        end
      elsif args.empty?
        rule(sym)
      else
        raise(NoMethodError, "undefined method `#{sym}' for #{inspect}")
      end
    end
  end
end
