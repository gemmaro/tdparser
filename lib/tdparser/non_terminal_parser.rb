module TDParser
  class NonTerminalParser < Parser # :nodoc:
    attr_reader :context, :symbol, :options

    def initialize(context, sym, *options)
      @context = context
      @symbol = sym
      @options = options
    end

    def call(tokens, buff)
      res = nil
      case @symbol
      when Symbol, String
        res = @context.__send__(@symbol, *@options).call(tokens, buff)
      when Parser
        res = @symbol.call(tokens, buff)
      end
      res
    end

    def ==(other)
      (self.class == other.class) &&
        (@context == other.context) &&
        (@symbol == other.symbol) &&
        (@options == other.options)
    end

    def to_s
      @symbol.to_s
    end
  end
end
