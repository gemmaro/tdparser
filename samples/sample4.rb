# frozen_string_literal: true

# -*- ruby -*-
# caching constructed grammars

require 'tdparser'
require 'tdparser/utils'

class Sample4Parser
  include TDParser

  def expr1
    (rule(:expr2) - (((token('+') | token('-')) - rule(:expr2)) * 0)) >> proc { |x|
      x[1].inject(x[0]) do |n, y|
        case y[0]
        when '+'
          n + y[1]
        when '-'
          n - y[1]
        end
      end
    }
  end

  def expr2
    (rule(:prim) - (((token('*') | token('/')) - rule(:prim)) * 0)) >> proc { |x|
      x[1].inject(x[0]) do |n, y|
        case y[0]
        when '*'
          n * y[1]
        when '/'
          n / y[1]
        end
      end
    }
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
    tokens = str.split(%r{(?:\s+)|([()+\-*/])}).reject { |x| x == '' }
    expr1.parse(tokens)
  end
end

ENV.fetch('TEST', nil) and return

parser = Sample4Parser.new
puts("1+10 = #{parser.parse('1+10')}")
puts("2-1*20+18 = #{parser.parse('2 - 1 * 20 + 18')}")
puts("2-(1-20) = #{parser.parse('2 - (1 - 20)')}")
puts("1+2-3 = #{parser.parse('1 + 2 - 3')}")
