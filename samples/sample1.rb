# frozen_string_literal: true

# adder-substractor

require 'tdparser'

class MyParser
  include TDParser

  def expr
    (token(/\d+/) - (((token("+") | token("-")) - token(/\d+/)) * 0)) >> proc { |x|
      n = x[0].to_i
      x[1].inject(n) { |acc, i|
        case i[0]
        when "-"
          acc - i[1].to_i
        when "+"
          acc + i[1].to_i
        end
      }
    }
  end

  def parse(str)
    tokens = str.split(%r{(?:\s+)|([+\-*/])}).select { |x| x != "" }
    expr.parse(tokens)
  end
end

ENV.fetch("TEST", nil) and return

parser = MyParser.new
puts("1+10 = " + parser.parse("1+10").to_s)
puts("2-1-20 = " + parser.parse("2 - 1 - 20").to_s)
puts("1+2-3 = " + parser.parse("1 + 2 - 3").to_s)
