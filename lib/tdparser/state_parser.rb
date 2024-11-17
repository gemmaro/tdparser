module TDParser
  class StateParser < Parser # :nodoc:
    attr_reader :state

    def initialize(s)
      @state = s
    end

    def call(_tokens, buff)
      return unless buff.map[:state] == @state

      Sequence[@state]
    end

    def to_s
      "<state:#{@state}>"
    end

    def ==(other)
      super(other) &&
        (@state == other.state)
    end

    def same?(_r)
      false
    end
  end
end
