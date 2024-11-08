# frozen_string_literal: true

require 'tdparser'
require 'benchmark'

# disable auto optimization
module TDParser
  class Parser
    def |(other)
      ChoiceParser.new(self, other)
    end
  end
end

parser = TDParser.define do |g|
  f = proc { |x| x.flatten }
  g.rule1 =
    ((token('1') - token('2') - rule1 - token('a')) >> f) |
    ((token('1') - token('2') - rule1 - token('b')) >> f) |
    empty

  g.rule2 =
    (((token('1') - token('2') - rule2 - token('a')) >> f) |
     ((token('1') - token('2') - rule2 - token('b')) >> f) |
     empty).optimize

  g.rule3 =
    (((token('1') - token('2') - rule3 - (token('a') | token('b'))) >> f) |
     empty)
end

puts(parser.rule1.to_s)
puts(parser.rule2.to_s)
puts(parser.rule3.to_s)

N = 10
Benchmark.bm do |x|
  buff = %w[1 2]
  b = ['b']
  [5, 10, 15].each do |i|
    puts('--')
    x.report { N.times { $r1 = parser.rule1.parse((buff * i) + (b * i)) } }
    x.report { N.times { $r2 = parser.rule2.parse((buff * i) + (b * i)) } }
    x.report { N.times { $r3 = parser.rule3.parse((buff * i) + (b * i)) } }
  end
end
