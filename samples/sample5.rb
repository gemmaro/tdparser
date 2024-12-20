# frozen_string_literal: true

# -*- ruby -*-
# writing grammars in the substitution style.

require 'tdparser'
require 'tdparser/utils'

parser = TDParser.define do |g|
  g.plus = '+'
  g.minus = '-'
  g.mult = '*'
  g.div = '/'

  g.expr1 =
    (g.expr2 - (((g.plus | g.minus) - g.expr2) * 0)) >> proc { |x|
      x[1].inject(x[0])  do |n, y|
        case y[0]
        when '+'
          n + y[1]
        when '-'
          n - y[1]
        end
      end
    }

  g.expr2 =
    (g.prim - (((g.mult | g.div) - g.prim) * 0)) >> proc { |x|
      x[1].inject(x[0]) do |n, y|
        case y[0]
        when '*'
          n * y[1]
        when '/'
          n / y[1]
        end
      end
    }

  g.prim =
    (g.token(:int) >> proc { |x| x[0].value.to_i }) |
    ((g.token('(') - g.expr1 - g.token(')')) >> proc { |x| x[1] })

  def parse(str)
    tokenizer = TDParser::StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
end

if ENV['TEST']
  Sample5Parser = parser
  return
end

puts("1+10 = #{parser.parse('1+10')}")
puts("2-1*20+18 = #{parser.parse('2 - 1 * 20 + 18')}")
puts("2-(1-20) = #{parser.parse('2 - (1 - 20)')}")
puts("1+2-3 = #{parser.parse('1 + 2 - 3')}")
