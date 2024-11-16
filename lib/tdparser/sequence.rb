module TDParser
  class Sequence < Array
    def +(other)
      dup.concat(other)
    end
  end
end
