module TDParser
  class StackrefParser < ReferenceParser # :nodoc:
    attr_reader :stack, :equality

    def initialize(stack, eqsym)
      @stack = stack
      @equality = eqsym
    end

    def call(tokens, buff)
      ys = @stack.pop
      if ys.nil? || ys.empty?
        nil
      else
        back_ref(ys.dup, @equality).call(tokens, buff)
      end
    end

    def to_s
      "<stackref:#{@stack.object_id}>"
    end

    def ==(other)
      super(other) &&
        @stack.equal?(other.stack) &&
        (@equality == other.equality)
    end
  end
end
