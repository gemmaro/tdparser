module TDParser
  class Grammar
    include TDParser

    alias define instance_eval

    def method_missing(sym, *args) # :nodoc:
      args.empty? and return rule(sym)
      sym.end_with?('=') or raise(NoMethodError, "undefined method `#{sym}' for #{self.inspect}")
      parser, = args
      parser.is_a?(Parser) or parser = token(parser)
      self.class.instance_eval {
        name = sym[0..-2]
        method_defined?(name) and return
        define_method(name) { parser }
      }
    end
  end
end
