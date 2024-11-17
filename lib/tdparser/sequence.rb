module TDParser
  class Sequence < Array # :nodoc:
    def +(other)
      dup.concat(other)
    end
  end
end
