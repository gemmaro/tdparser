module TDParser
  class ActionParser < CompositeParser
    attr_reader :action

    def initialize(parser, act)
      @action = act
      super(parser)
    end

    def call(tokens, buff)
      if (x = @parsers[0].call(tokens, buff)).nil?
        nil
      else
        x = TokenBuffer[*x]
        x.map = buff.map
        Sequence[@action[x]]
      end
    end

    def ==(other)
      super(other) &&
        (@action == other.action)
    end

    def to_s
      "(#{@parsers[0]} <action>)"
    end
  end
end
