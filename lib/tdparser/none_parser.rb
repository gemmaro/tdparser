module TDParser
  class NoneParser < Parser # :nodoc:
    def call(tokens, _buff)
      t = tokens.shift
      return unless t.nil?

      Sequence[nil]
    end

    def to_s
      '<none>'
    end

    def ==(_other)
      true
    end
  end
end
