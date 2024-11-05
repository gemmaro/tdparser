# -*- ruby -*-
# caching constructed grammars

require 'tdparser'
require 'tdparser/utils'

class Sample4Parser
  include TDParser

  def expr1
    rule(:expr2) - ((token("+")|token("-")) - rule(:expr2))*0 >> proc{|x|
      x[1].inject(x[0]){|n,y|
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
    rule(:prim) - ((token("*")|token("/")) - rule(:prim))*0 >> proc{|x|
      n = x[0]
      x[1].inject(x[0]){|n,y|
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
    token(:int) >> proc{|x| x[0].value.to_i } |
    token("(") - rule(:expr1) - token(")") >> proc{|x| x[1] }
  end

  def parse(str)
    tokenizer = StringTokenizer[
      /\d+(?!\.\d)/ => :int,
      /\d+\.\d+/ => :real,
    ]
    expr1.parse(tokenizer.generate(str))
  end
end

class FastParser < Sample4Parser
  def expr1
    @expr1 ||= super()
  end

  def expr2
    @expr2 ||= super()
  end

  def prim
    @prim  ||= super()
  end

  def parse(str)
    tokens = str.split(/(?:\s+)|([\(\)\+\-\*\/])/).select{|x| x != ""}
    expr1.parse(tokens)
  end
end

ENV["TEST"] and return

parser = Sample4Parser.new
puts("1+10 = " + parser.parse("1+10").to_s)
puts("2-1*20+18 = " + parser.parse("2 - 1 * 20 + 18").to_s)
puts("2-(1-20) = " + parser.parse("2 - (1 - 20)").to_s)
puts("1+2-3 = " + parser.parse("1 + 2 - 3").to_s)
