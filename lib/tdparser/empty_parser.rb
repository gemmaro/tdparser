module TDParser
  class EmptyParser < Parser # :nodoc:
    def call(_tokens, _buff)
      Sequence[nil]
    end

    def to_s
      '<empty>'
    end

    def ==(_other)
      true
    end
  end
end
