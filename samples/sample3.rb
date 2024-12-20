# frozen_string_literal: true

# -*- ruby -*-
# parsing four arithmetic expressions with tdputils.

require 'tdparser'
require 'tdparser/utils'

class Sample3Parser
  include TDParser

  def expr1
    n = nil
    ((rule(:expr2) >> proc { |x| n = x[0] }) -
      ((((token('+') | token('-')) - rule(:expr2)) >> proc { |x|
        case x[0]
        when '+'
          n += x[1]
        when '-'
          n -= x[1]
        end
        n
      }) * 0)) >> proc { n }
  end

  def expr2
    n = nil
    ((rule(:prim) >> proc { |x| n = x[0] }) -
      ((((token('*') | token('/')) - rule(:prim)) >> proc { |x|
        case x[0]
        when '*'
          n *= x[1]
        when '/'
          n /= x[1]
        end
        n
      }) * 0)) >> proc { n }
  end

  def prim
    (token(:int) >> proc { |x| x[0].value.to_i }) |
      ((token('(') - rule(:expr1) - token(')')) >> proc { |x| x[1] })
  end

  def parse(str)
    tokenizer = StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
end

ENV.fetch('TEST', nil) and return

parser = Sample3Parser.new
puts("1+10 = #{parser.parse('1+10')}")
puts("2-1*20+18 = #{parser.parse('2 - 1 * 20 + 18')}")
puts("2-(1-20) = #{parser.parse('2 - (1 - 20)')}")
puts("1+2-3 = #{parser.parse('1 + 2 - 3')}")
