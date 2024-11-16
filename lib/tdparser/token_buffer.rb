module TDParser
  class TokenBuffer < Array
    attr_accessor :map, :state

    def initialize(*args)
      super(*args)
      @map = {}
    end

    def [](idx)
      case idx
      when Symbol, String
        @map[idx]
      else
        super(idx)
      end
    end

    def []=(idx, val)
      case idx
      when Symbol, String
        @map[idx] = val
      else
        super(idx, val)
      end
    end

    def clear
      super()
      @map.clear
    end
  end
end
