module TDParser
  class ChoiceParser < CompositeParser
    def call(tokens, buff)
      b = prepare(buff)
      if (x = @parsers[0].call(tokens, b)).nil?
        recover(b, tokens)
        @parsers[1].call(tokens, buff)
      else
        buff.insert(0, *b)
        x
      end
    end

    def to_s
      "(#{@parsers[0]} | #{@parsers[1]})"
    end

    def shared_sequence(r1, r2)
      if r1.is_a?(ConcatParser) && r2.is_a?(ConcatParser)
        r11 = r1.parsers[0]
        r12 = r1.parsers[1]
        r21 = r2.parsers[0]
        r22 = r2.parsers[1]
        if r11.same?(r21)
          share, r12, r22, = shared_sequence(r12, r22)
          return [r11 - share, r12, r22] if share

          return [r11, r12, r22]

        end
      end
      [nil, r1, r2]
    end

    def optimize(default = false)
      r1 = @parsers[0]
      r2 = @parsers[1]
      if r1.is_a?(ActionParser)
        act1 = r1.action
        r1 = r1.parsers[0]
      end
      if r2.is_a?(ActionParser)
        act2 = r2.action
        r2 = r2.parsers[0]
      end
      share, r12, r22, = shared_sequence(r1, r2)
      if share
        r = share - (r12 + r22)
        if act1
          r = if act2
                r >> proc do |x|
                  y0, y1, *_ = x.pop
                  if y0
                    act1.call(x.push(*y0))
                  else
                    act2.call(x.push(*y1))
                  end
                end
              else
                r >> proc do |x|
                  y0, = x.pop
                  act1.call(x.push(*y0)) if y0
                end
              end
        elsif act2
          r = r >> proc do |x|
                     _, y1, = x.pop
                     act2.call(x.push(*y1)) if y1
                   end
        end
        return r
      end
      if default
        dup
      else
        super(default)
      end
    end
  end
end
