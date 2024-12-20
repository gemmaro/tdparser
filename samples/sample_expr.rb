# frozen_string_literal: true

# -*- ruby -*-
# writing grammars using chainl().

require 'tdparser'
require 'tdparser/utils'

parser = TDParser.define do |g|
  g.plus = '+'
  g.minus = '-'
  g.mult = '*'
  g.div = '/'

  g.expr1 =
    chainl(prim, mult | div, plus | minus) do |x|
      case x[1]
      when '+'
        x[0] + x[2]
      when '-'
        x[0] - x[2]
      when '*'
        x[0] * x[2]
      when '/'
        x[0] / x[2]
      end
    end

  g.prim =
    (token(:int) >> proc { |x| x[0].value.to_i }) |
    ((token('(') - expr1 - token(')')) >> proc { |x| x[1] })

  def parse(str)
    tokenizer = TDParser::StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
end

if ENV['TEST']
  SampleExprParser = parser
  return
end

puts("1 = #{parser.parse('1')}")
puts("1+10 = #{parser.parse('1+10')}")
puts("2-1*20+18 = #{parser.parse('2 - 1 * 20 + 18')}")
puts("2-(1-20) = #{parser.parse('2 - (1 - 20)')}")
puts("1+2-3 = #{parser.parse('1 + 2 - 3')}")
