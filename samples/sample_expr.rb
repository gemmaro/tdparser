# -*- ruby -*-
# writing grammars using chainl().

require 'tdp'
require 'tdp/utils'

parser = TDParser.define{|g|
  g.plus = "+"
  g.minus = "-"
  g.mult = "*"
  g.div = "/"

  g.expr1 =
    chainl(prim, mult|div, plus|minus){|x|
      case x[1]
      when "+"
        x[0] + x[2]
      when "-"
        x[0] - x[2]
      when "*"
        x[0] * x[2]
      when "/"
        x[0] / x[2]
      end
    }

  g.prim =
    token(:int) >> proc{|x| x[0].value.to_i } |
    token("(") - expr1 - token(")") >> proc{|x| x[1] }

  def parse(str)
    tokenizer = TDPUtils::StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
}

puts("1 = " + parser.parse("1").to_s())
puts("1+10 = " + parser.parse("1+10").to_s())
puts("2-1*20+18 = " + parser.parse("2 - 1 * 20 + 18").to_s())
puts("2-(1-20) = " + parser.parse("2 - (1 - 20)").to_s())
puts("1+2-3 = " + parser.parse("1 + 2 - 3").to_s())
