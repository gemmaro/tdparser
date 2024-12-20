# frozen_string_literal: true

require 'test_helper'
require 'tdparser'
require 'tdparser/utils'
require 'tdparser/xml'

class Tokens
  include Enumerable

  def initialize(str)
    @str = str
  end

  def each
    @str.each_byte { |c| yield(c.chr) }
  end
end

class Calculator
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
    tokenizer = StringTokenizer.new({
                                      /\d+/ => :int
                                    })
    expr1.parse(tokenizer.generate(str))
  end
end

Calculator2 = TDParser.define do |g|
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
    (g.token(:int) >> proc { |x| x[0].value.to_i }) |
    ((g.token('(') - g.expr1 - g.token(')')) >> proc { |x| x[1] })

  def parse(str)
    tokenizer = TDParser::StringTokenizer.new({
                                                /\d+/ => :int
                                              })
    expr1.parse(tokenizer.generate(str))
  end
end

LeftResursiveCalculator = TDParser.define do |g|
  g.plus = '+'
  g.minus = '-'
  g.mult = '*'
  g.div = '/'

  g.expr1 =
    ((g.plus | g.minus) - g.expr1) >> proc { |x|
      n = x[0]
      x[1].each do |y|
        case y[0]
        when '+'
          n += y[1]
        when '-'
          n -= y[1]
        end
      end
      n
    }
  g.expr1 |= g.expr2

  g.expr2 =
    ((g.mult | g.div) - g.expr2) >> proc { |x|
      n = x[0]
      x[1].each do |y|
        case y[0]
        when '*'
          n *= y[1]
        when '/'
          n /= y[1]
        end
      end
      n
    }
  g.expr2 |= g.prim

  g.prim =
    (g.token(:int) >> proc { |x| x[0].value.to_i }) |
    ((g.token('(') - g.expr1 - g.token(')')) >> proc { |x| x[1] })

  def parse(str)
    tokenizer = TDParser::StringTokenizer.new({
                                                /\d+/ => :int
                                              })
    expr1.parse(tokenizer.generate(str))
  end
end

class TestTDParser < Test::Unit::TestCase
  include TDParser

  def setup
    @calc = Calculator.new
  end

  def test_sequence1
    abc = 'abc'
    rule = (token('a') - token('b') - token('c')) >> proc { |arg| arg.join }
    assert_equal(abc, rule.parse(Tokens.new(abc)))
  end

  def test_sequence2
    abc = 'aBc'
    rule = (token('a') - token('b') - token('c')) >> proc { |arg| arg.join }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_sequence3
    abc = 'abC'
    rule = (token('a') - token('b') - token('c')) >> proc { |arg| arg.join }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_sequence4
    abc = 'ab'
    rule = (token('a') - token('b') - token('c')) >> proc { |arg| arg.join }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_sequence5
    abc = 'abc'
    rule = (any - any - any) >> proc { |arg| arg.join }
    assert_equal(abc, rule.parse(Tokens.new(abc)))
  end

  def test_sequence6
    abc = 'abc'
    rule = (any - any - any - empty) >> proc { |arg| arg }
    assert_equal(['a', 'b', 'c', nil], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence7
    abc = 'abc'
    rule = (any - any - (empty | any)) >> proc { |arg| arg }
    assert_equal(['a', 'b', nil], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence8
    abc = 'abc'
    rule = (any - any - (any | empty)) >> proc { |arg| arg }
    assert_equal(%w[a b c], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence9
    abc = 'abc'
    rule = (any - any - any - (any | empty)) >> proc { |arg| arg }
    assert_equal(['a', 'b', 'c', nil], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence10
    abc = 'ab'
    rule = (any - any - none) >> proc { |arg| arg }
    assert_equal(['a', 'b', nil], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence11
    abc = 'abc'
    rule = (any - any - none) >> proc { |arg| arg }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_sequence12
    abc = 'abc'
    rule = (any - any - ~token('c')) >> proc { |arg| arg }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_sequence13
    abc = 'aba'
    rule = (any - any - ~token('c') - any) >> proc { |arg| arg }
    assert_equal(['a', 'b', ['a'], 'a'], rule.parse(Tokens.new(abc)).to_a)
  end

  def test_sequence14
    abc = 'aba'
    rule1 = token('a') - token('b')
    rule2 = (~rule(rule1) - any - any - any) >> proc { |arg| arg }
    assert_equal(nil, rule2.parse(Tokens.new(abc)))
  end

  def test_sequence15
    abc = 'aca'
    rule1 = token('a') - token('b')
    rule2 = (~rule(rule1) - any - any - any) >> proc { |arg| arg }
    assert_equal([%w[a c], 'a', 'c', 'a'], rule2.parse(Tokens.new(abc)).to_a)
  end

  def test_generator1
    generator = TDParser::TokenGenerator.new { |x| %w[a b c].each { |e| x.yield(e) } }
    rule = (any - any - any - (any | empty)) >> proc { |arg| arg }
    assert_equal(['a', 'b', 'c', nil], rule.parse(generator).to_a)
  end

  def test_generator2
    rule = (any - any - any - (any | empty)) >> proc { |arg| arg }
    result = rule.parse { |x| %w[a b c].each { |e| x.yield(e) } }

    assert_equal(['a', 'b', 'c', nil], result.to_a)
  end

  def test_iteration1
    abc = 'abcabc'
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 0) >> proc { |arg| arg.join }
    assert_equal(abc, rule.parse(Tokens.new(abc)))
  end

  def test_iteration2
    abc = 'aBcabc'
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 0) >> proc { |arg| arg.join }
    assert_equal(abc, rule.parse(Tokens.new(abc)))
  end

  def test_iteration3
    abc = ''
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 0) >> proc { |arg| arg.join }
    assert_equal(abc, rule.parse(Tokens.new(abc)))
  end

  def test_iteration4
    abc = ''
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 1) >> proc { |arg| arg.join }
    assert_equal(nil, rule.parse(Tokens.new(abc)))
  end

  def test_iteration5
    abc = 'aBCAbc'
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 0) >> proc { |arg| arg.join }
    assert_equal('aBC', rule.parse(Tokens.new(abc)))
    assert_equal('A', rule.peek)
  end

  def test_iteration6
    abc = 'aBCaBcd'
    rule = ((token('a') - (token('b') | token('B')) - (token('c') | token('C'))) * 0) >> proc { |arg| arg.join }
    assert_equal('aBCaBc', rule.parse(Tokens.new(abc)))
    assert_equal('d', rule.peek)
  end

  def test_iteration7
    buff = %w[a b b b c]
    rule = (token('a') - (token('b') * 1) - token('c')) >> proc { |x| x }
    assert_equal(['a', [['b'], ['b'], ['b']], 'c'], rule.parse(buff).to_a)
  end

  def test_iteration8
    buff = %w[a b b b c]
    rule = (token('a') - (token('b') * 4) - token('c')) >> proc { |x| x }
    assert_equal(nil, rule.parse(buff))
  end

  def test_iteration9
    buff = %w[a b c]
    rule = (token('a') - (token('b') * (2..4)) - token('c')) >> proc { |x| x }
    assert_equal(nil, rule.parse(buff))
  end

  def test_iteration10
    buff = %w[a b b b c]
    rule = (token('a') - (token('b') * (2..4)) - token('c')) >> proc { |x| x }
    assert_equal(['a', [['b'], ['b'], ['b']], 'c'], rule.parse(buff).to_a)
  end

  def test_iteration11
    buff = %w[a b a b c]
    rule = (((token('a') - token('b')) * 1) - token('c')) >> proc { |x| x }
    assert_equal([[%w[a b], %w[a b]], 'c'], rule.parse(buff).to_a)
  end

  def test_iteration12
    buff = ['c']
    rule = (token('c') - ((token('a') - token('b')) * 1)) >> proc { |x| x }
    assert_equal(nil, rule.parse(buff))
  end

  def test_regex_match
    rule = token(/\d+/, :=~) >> proc { |x| x[0].to_i }
    assert_equal(10, rule.parse(['10']))
  end

  def test_reference1
    buff = %w[a b c]
    rule = ((token('a') / :a) - (token('b') / :b) - (token('c') / :c)) >> proc { |x| [x[:a], x[:b], x[:c]] }
    assert_equal([['a'], ['b'], ['c']], rule.parse(buff))
  end

  def test_reference2
    buff = %w[a b c]
    rule = (((token('a') - token('b')) / :n) - token('c')) >> proc { |x| x[:n] }
    assert_equal(%w[a b], rule.parse(buff))
  end

  def test_reference3
    buff = %w[a b c]
    stack = []
    rule = (((token('a') - token('b')) % stack) - (token('c') % stack)) >> proc { |x| x }
    assert_equal(%w[a b c], rule.parse(buff).to_a)
    assert_equal([%w[a b], ['c']], stack)
  end

  def test_backref1
    buff = %w[a b a]
    rule = ((token(/\w/) / :x) - token('b') - backref(:x)) >> proc { |x| x }
    assert_equal(%w[a b a], rule.parse(buff).to_a)
  end

  def test_backref2
    buff = %w[a b c]
    rule = ((token(/\w/) / :x) - token('b') - backref(:x)) >> proc { |x| x }
    assert_equal(nil, rule.parse(buff))
  end

  def test_backref3
    buff = %w[a b a b a b]
    rule = (((token(/\w/) - token(/\w/)) / :x) - (backref(:x) * 0)) >> proc { |x| x }
    assert_equal(['a', 'b', [%w[a b], %w[a b]]], rule.parse(buff).to_a)
  end

  def test_backref4
    rule = (((token(/\w/) - token(/\w/)) / :x) - ((token('-') | backref(:x)) * 0)) >> proc { |x| x }
    assert_equal(['a', 'b', [%w[a b], %w[a b]]],
                 rule.parse(%w[a b a b a b]).to_a)
    assert_equal(['a', 'b', [['-'], ['a', 'b']]],
                 rule.parse(['a', 'b', '-', 'a', 'b']).to_a)
  end

  def test_stackref1
    buff = %w[a b a]
    stack = []
    rule = ((token(/\w/) % stack) - token('b') - stackref(stack)) >> proc { |x| x }
    assert_equal(%w[a b a], rule.parse(buff).to_a)
  end

  def test_stackref2
    buff = %w[a b c]
    stack = []
    rule = ((token(/\w/) % stack) - token('b') - stackref(stack)) >> proc { |x| x }
    assert_equal(nil, rule.parse(buff))
  end

  def test_stackref3
    buff = %w[a b a b a b]
    stack = []
    rule = (((token(/\w/) - token(/\w/)) % stack) - ((stackref(stack) % stack) * 0)) >> proc { |x| x }
    assert_equal(['a', 'b', [%w[a b], %w[a b]]], rule.parse(buff).to_a)

    buff = %w[a b a b a b]
    stack = []
    rule = (((token(/\w/) - token(/\w/)) % stack) - (stackref(stack) * 0)) >> proc { |x| x }
    assert_equal(['a', 'b', [%w[a b]]], rule.parse(buff).to_a)
  end

  def test_parallel1
    rule = (token('a') - (token('b') + token('c'))) >> proc { |x| x }
    assert_equal(['a', [['b'], nil]], rule.parse(%w[a b]).to_a)
    assert_equal(['a', [nil, ['c']]], rule.parse(%w[a c]).to_a)
  end

  def test_parallel2
    rule = (token('a') - token('b') - (token('c') + token('d'))) >> proc { |x| x }
    assert_equal(['a', 'b', [['c'], nil]], rule.parse(%w[a b c]).to_a)
    assert_equal(['a', 'b', [nil, ['d']]], rule.parse(%w[a b d]).to_a)
  end

  def test_optimize1
    rule =
      ((token('a') - token('b') - token('c')) >> proc { |x| x }) |
      ((token('a') - token('b') - token('d')) >> proc { |x| x })
    rule = rule.optimize(false)
    assert_equal(%w[a b c], rule.parse(%w[a b c]))
    assert_equal(%w[a b d], rule.parse(%w[a b d]))
  end

  def test_chainl1
    buff = ['3', '-', '2', '-', '1']
    rule = chainl(token(/\d+/) >> proc { |x| x[0].to_i }, token('-')) do |x|
      x[0] - x[2]
    end
    assert_equal(0, rule.parse(buff))
  end

  def test_chainl2
    buff = ['3', '-', '2', '*', '2', '-', '1']
    rule = chainl(token(/\d+/) >> proc { |x| x[0].to_i }, token('*'), token('-')) do |x|
      case x[1]
      when '-'
        x[0] - x[2]
      when '*'
        x[0] * x[2]
      end
    end
    assert_equal(-2, rule.parse(buff))
  end

  def test_chainr1
    buff = ['3', '-', '2', '-', '1']
    rule = chainr(token(/\d+/) >> proc { |x| x[0].to_i }, token('-')) do |x|
      x[0].to_i - x[2].to_i
    end
    assert_equal(2, rule.parse(buff))
  end

  def test_chainr2
    buff = ['3', '-', '2', '*', '2', '-', '1']
    rule = chainr(token(/\d+/) >> proc { |x| x[0].to_i }, token('*'), token('-')) do |x|
      case x[1]
      when '-'
        x[0] - x[2]
      when '*'
        x[0] * x[2]
      end
    end
    assert_equal(0, rule.parse(buff))
  end

  def test_condition1
    rule = (condition { |m| m['n'] = 20 } - condition { |m| m['n'] }) >> proc { |x| x }
    assert_equal([20, 20], rule.parse([]).to_a)
  end

  def test_condition2
    rule = (condition { |m| m['n'] = 20 } - condition { |m| m['n'] > 20 }) >> proc { |x| x }
    assert_equal(nil, rule.parse([]))
  end

  def test_condition3
    rule =
      (condition { |m| m['n'] = 20 } -
      ((token('a') - condition { |m| m['n'] > 20 }) |
       (token('b') - condition { |m| m['n'] > 10 }))) >> proc { |x| x }
    assert_equal(nil, rule.parse(['a']))
    assert_equal([20, 'b', true], rule.parse(['b']).to_a)
  end

  def test_rule1
    expr = '1 + 2'
    assert_equal(3, @calc.parse(expr))
  end

  def test_rule2
    expr = '1 - (2 + 3)'
    assert_equal(-4, @calc.parse(expr))
  end

  def test_rule3
    expr = '1 - 2 + 3'
    assert_equal(2, @calc.parse(expr))
  end

  def test_define
    assert_equal(1 + 10, Calculator2.parse('1+10'))
    assert_equal(2 - (1 * 20) + 18, Calculator2.parse('2 - 1 * 20 + 18'))
    assert_equal(2 - (1 - 20), Calculator2.parse('2 - (1 - 20)'))
    assert_equal(1 + 2 - 3,    Calculator2.parse('1 + 2 - 3'))
  end

  def test_tokenizer
    tokenizer = StringTokenizer.new({
                                      /\d+\.\d+/ => :real,
                                      /\d+(?!\.\d)/ => :int,
                                      %r{\+|-|\*|/} => :op
                                    })
    tokens = tokenizer.generate('1 + 1.0 - 2').to_a
    kinds = tokens.collect(&:kind)
    vals = tokens.collect(&:value)
    assert_equal(%i[int op real op int], kinds)
    assert_equal(['1', '+', '1.0', '-', '2'], vals)
  end
end
