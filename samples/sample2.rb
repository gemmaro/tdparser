# frozen_string_literal: true

# -*- ruby -*-
# parsing four arithmetic expressions with tdputils.

require 'tdp'
require 'tdp/utils'

class MyParser
  include TDParser
  include TDPUtils

  def expr1
    (rule(:expr2) - (((token("+") | token("-")) - rule(:expr2)) * 0)) >> proc { |x|
      x[1].inject(x[0]) { |n,y|
        case y[0]
        when "+"
          n + y[1]
        when "-"
          n - y[1]
        end
      }
    }
  end

  def expr2
    (rule(:prim) - (((token("*") | token("/")) - rule(:prim)) * 0)) >> proc { |x|
      x[1].inject(x[0]) { |n, y|
        case y[0]
        when "*"
          n * y[1]
        when "/"
          n / y[1]
        end
      }
    }
  end

  def prim
    (token(:int) >> proc { |x| x[0].value.to_i }) |
    ((token("(") - rule(:expr1) - token(")")) >> proc { |x| x[1] })
  end

  def parse(str)
    tokenizer = StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
end

parser = MyParser.new
puts("1+10 = " + parser.parse("1+10").to_s())
puts("2-1*20+18 = " + parser.parse("2 - 1 * 20 + 18").to_s())
puts("2-(1-20) = " + parser.parse("2 - (1 - 20)").to_s())
puts("1+2-3 = " + parser.parse("1 + 2 - 3").to_s())
