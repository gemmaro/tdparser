module TDParser
  class TerminalParser < Parser
    attr_reader :symbol, :equality

    def initialize(obj, eqsym)
      @symbol   = obj
      @equality = eqsym
    end

    def call(tokens, buff)
      t = tokens.shift
      buff.unshift(t)
      return unless @symbol.__send__(@equality, t) || t.__send__(@equality, @symbol)

      Sequence[t]
    end

    def ==(other)
      (self.class == other.class) &&
        (@symbol == other.symbol) &&
        (@equality == other.equality)
    end

    def to_s
      @symbol.to_s
    end
  end
end
