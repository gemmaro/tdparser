module TDParser
  class ConcatParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      if (x = @parsers[0].call(tokens, buff)).nil?
        nil
      elsif (y = @parsers[1].call(tokens, buff)).nil?
        nil
      else
        x + y
      end
    end

    def -(other)
      @parsers[0] - (@parsers[1] - other)
    end

    def to_s
      "(#{@parsers[0]} #{@parsers[1]})"
    end
  end
end
