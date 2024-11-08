# frozen_string_literal: true

# -*- ruby -*-
# adder-substractor

require 'tdparser'

class MyParser
  include TDParser

  def expr
    (token(/\d+/) - (((token('+') | token('-')) - token(/\d+/)) * 0)) >> proc { |x|
      n = x[0].to_i
      x[1].inject(n) do |acc, i|
        case i[0]
        when '-'
          acc - i[1].to_i
        when '+'
          acc + i[1].to_i
        end
      end
    }
  end

  def parse(str)
    tokens = str.split(%r{(?:\s+)|([+\-*/])}).reject { |x| x == '' }
    expr.parse(tokens)
  end
end

ENV.fetch('TEST', nil) and return

parser = MyParser.new
puts("1+10 = #{parser.parse('1+10')}")
puts("2-1-20 = #{parser.parse('2 - 1 - 20')}")
puts("1+2-3 = #{parser.parse('1 + 2 - 3')}")
