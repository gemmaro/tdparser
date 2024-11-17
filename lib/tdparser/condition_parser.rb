module TDParser
  class ConditionParser < Parser # :nodoc:
    attr_reader :condition

    def initialize(&condition)
      @condition = condition
    end

    def call(_tokens, buff)
      return unless (res = @condition.call(buff.map))

      Sequence[res]
    end

    def to_s
      "<condition:#{@condition}>"
    end

    def ==(other)
      super(other) &&
        (@condition == other.condition)
    end

    def same?(_r)
      false
    end
  end
end
