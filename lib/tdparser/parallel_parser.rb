module TDParser
  class ParallelParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      b = prepare(buff)
      if (x = @parsers[0].call(tokens, b)).nil?
        recover(b, tokens)
        Sequence[Sequence[nil, @parsers[1].call(tokens, buff)]]
      else
        buff.insert(0, *b)
        Sequence[Sequence[x, nil]]
      end
    end

    def to_s
      "(#{@parsers[0]} + #{@parsers[1]})"
    end
  end
end
