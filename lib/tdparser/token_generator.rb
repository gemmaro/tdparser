module TDParser
  class TokenGenerator
    def initialize(args = nil, &block)
      enumerator = Enumerator.new do |y|
        if args
          args.each { |arg| y << arg }
        else
          block.call(y)
        end
      end
      @enumerator = enumerator

      @buffer = []
    end

    def next
      @enumerator.next
    end

    def next?
      @enumerator.peek
      true
    rescue StopIteration
      false
    end

    def to_a
      @enumerator.to_a
    end

    def shift
      if @buffer.empty?
        (self.next if next?)
      else
        @buffer.shift
      end
    end

    def unshift(*token)
      @buffer.unshift(*token)
    end
  end
end
