module TDParser
  class NegativeParser < CompositeParser
    def call(tokens, buff)
      b = prepare(buff)
      r = @parsers[0].call(tokens, b)
      rev = b.reverse
      recover(b, tokens)
      return unless r.nil?

      Sequence[Sequence[*rev]]
    end

    def to_s
      "~#{@parsers[0]}"
    end
  end
end
