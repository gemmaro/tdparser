module TDParser
  class StackParser < CompositeParser # :nodoc:
    attr_reader :stack

    def initialize(parser, stack)
      @stack = stack
      super(parser)
    end

    def call(tokens, buff)
      x = @parsers[0].call(tokens, buff)
      @stack.push(x)
      x
    end

    def ==(other)
      super(other) &&
        (@stack == other.stack)
    end

    def same?(_r)
      false
    end

    def to_s
      "<stack:#{@stack.object_id}>"
    end
  end
end
