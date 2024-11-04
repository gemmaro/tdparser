# frozen_string_literal: true

require 'tdp'
require 'benchmark'

# disable auto optimization
module TDParser
  class Parser
    def |(r)
      ChoiceParser.new(self, r)
    end
  end
end

parser = TDParser.define{|g|
  f = Proc.new{|x| x.flatten}
  g.rule1 =
    ((token("1") - token("2") - rule1 - token("a")) >> f) |
    ((token("1") - token("2") - rule1 - token("b")) >> f) |
    empty()


  g.rule2 =
    (((token("1") - token("2") - rule2 - token("a")) >> f) |
     ((token("1") - token("2") - rule2 - token("b")) >> f) |
     empty()).optimize()

  g.rule3 =
    (((token("1") - token("2") - rule3 - (token("a") | token("b"))) >> f) |
     empty())
}

puts(parser.rule1.to_s)
puts(parser.rule2.to_s)
puts(parser.rule3.to_s)

N = 10
Benchmark.bm{|x|
  buff = ["1","2"]
  b = ["b"]
  for i in [5,10,15]
    puts("--")
    x.report{ N.times{ $r1 = parser.rule1.parse((buff * i) + (b * i)) } }
    x.report{ N.times{ $r2 = parser.rule2.parse((buff * i) + (b * i)) } }
    x.report{ N.times{ $r3 = parser.rule3.parse((buff * i) + (b * i)) } }
  end
}
