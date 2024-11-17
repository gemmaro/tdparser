module TDParser
  class FailParser < Parser # :nodoc:
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
