# frozen_string_literal: true

module TDParser
  class Grammar
    include TDParser

    alias define instance_eval

    def respond_to_missing? # :nodoc:
      true
    end

    def method_missing(sym, *args) # :nodoc:
      args.empty? and return rule(sym)
      sym.end_with?('=') or raise(NoMethodError, "undefined method `#{sym}' for #{inspect}")
      name = sym[0..-2]
      klass = self.class
      klass.method_defined?(name) and return
      parser, = args
      parser.is_a?(Parser) or parser = token(parser)
      klass.define_method(name) { parser }
    end
  end
end
