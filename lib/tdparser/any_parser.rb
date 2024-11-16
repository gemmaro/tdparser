module TDParser
  class AnyParser < Parser
    def call(tokens, _buff)
      t = tokens.shift
      if t.nil?
        nil
      else
        Sequence[t]
      end
    end

    def to_s
      '<any>'
    end

    def ==(_other)
      true
    end
  end
end
