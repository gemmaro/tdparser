module TDParser
  class IterationParser < CompositeParser
    attr_reader :min, :range

    def initialize(parser, n, range)
      @min = n
      @range = range
      super(parser)
    end

    def call(ts, buff)
      r = @parsers[0]
      n = @min
      x  = true
      xs = []
      while n.positive?
        n -= 1
        b = prepare(buff)
        if (x = r.call(ts, b)).nil?
          recover(b, ts)
          break
        else
          buff.insert(0, *b)
          xs.push(x)
        end
      end
      if x.nil?
        nil
      else
        if range
          range.each do
            loop do
              y = x
              b = prepare(buff)
              if (x = r.call(ts, b)).nil?
                recover(b, ts)
                x = y
                break
              else
                buff.insert(0, *b)
                xs.push(x)
              end
            end
          end
        else
          loop do
            y = x
            b = prepare(buff)
            if (x = r.call(ts, b)).nil?
              recover(b, ts)
              x = y
              break
            else
              buff.insert(0, *b)
              xs.push(x)
            end
          end
        end
        Sequence[xs]
      end
    end

    def to_s
      "(#{@parsers[0]})*#{@range ? @range.to_s : @min.to_s}"
    end

    def ==(other)
      super(other) &&
        (@min == other.min) &&
        (@range == other.range)
    end
  end
end
