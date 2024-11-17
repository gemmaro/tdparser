module TDParser
  class Parser
    include BufferUtils
    include TDParser

    def to_proc
      proc { |*x| call(*x) }
    end

    def to_s
      '??'
    end

    def call(*args); end

    def optimize(_default = false)
      dup
    end

    def ==(_other)
      false
    end

    def same?(r)
      self == r
    end

    def -(other)
      ConcatParser.new(self, other)
    end

    def +(other)
      ParallelParser.new(self, other)
    end

    def |(other)
      ChoiceParser.new(self, other).optimize(true)
    end

    def *(other)
      if other.is_a?(Range)
        n = other.min
      else
        n = other
        other = nil
      end
      IterationParser.new(self, n, other)
    end

    def >>(other)
      ActionParser.new(self, other)
    end

    def /(other)
      LabelParser.new(self, other)
    end

    def %(other)
      StackParser.new(self, other)
    end

    def >(other)
      Parser.new do |tokens, buff|
        buff[other] = buff.dup
        self[tokens, buff]
      end
    end

    def ~@
      NegativeParser.new(self)
    end

    def parse(tokens = nil, buff = nil, &blk)
      buff ||= TokenBuffer.new
      @tokens = if blk.nil?
                  if tokens.respond_to?(:shift) && tokens.respond_to?(:unshift)
                    tokens
                  elsif tokens.respond_to?(:each)
                    TokenGenerator.new(tokens)
                  else
                    tokens
                  end
                else
                  TokenGenerator.new(&blk)
                end
      r = call(@tokens, buff)
      if r.nil?
        nil
      else
        r[0]
      end
    end

    def peek
      t = @tokens.shift
      @tokens.unshift(t) unless t.nil?
      t
    end

    def do(&block)
      self >> block
    end
  end
end
