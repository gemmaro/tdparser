module TDParser
  class FailParser < Parser
    def call(_tokens, _buff)
      nil
    end

    def to_s
      '<fail>'
    end

    def ==
      (self.class == r.class)
    end
  end
end
