# frozen_string_literal: true

# -*- ruby -*-
#
# Top-down parser for embedded in a ruby script.
#

require "tdparser/token_generator"
require "tdparser/token_buffer"
require "tdparser/buffer_utils"
require "tdparser/parser"
require "tdparser/sequence"
require "tdparser/non_terminal_parser"
require "tdparser/terminal_parser"
require "tdparser/composite_parser"
require "tdparser/action_parser"
require "tdparser/label_parser"
require "tdparser/stack_parser"
require "tdparser/concat_parser"
require "tdparser/choice_parser"
require "tdparser/parallel_parser"
require "tdparser/iteration_parser"
require "tdparser/negative_parser"
require "tdparser/fail_parser"
require "tdparser/empty_parser"
require "tdparser/any_parser"
require "tdparser/none_parser"
require "tdparser/reference_parser"
require "tdparser/backref_parser"
require "tdparser/stackref_parser"
require "tdparser/condition_parser"
require "tdparser/state_parser"
require "tdparser/grammar"

module TDParser
  ParserException = Class.new(RuntimeError) # :nodoc: Unused class

  include BufferUtils

  def rule(sym, *opts)
    NonTerminalParser.new(self, sym, *opts)
  end

  def token(x, eqsym = :===)
    TerminalParser.new(x, eqsym)
  end

  def back_ref(x, eqsym = :===)
    BackrefParser.new(x, eqsym)
  end

  alias backref back_ref

  def stack_ref(stack, eqsym = :===)
    StackrefParser.new(stack, eqsym)
  end

  alias stackref stack_ref

  def state(s)
    StateParser.new(s)
  end

  def empty_rule(&)
    EmptyParser.new(&)
  end
  alias empty empty_rule

  def any_rule
    AnyParser.new
  end
  alias any any_rule

  def none_rule
    NoneParser.new
  end
  alias none none_rule

  def fail_rule
    FailParser.new
  end
  alias fail fail_rule

  def condition_rule(&)
    ConditionParser.new(&)
  end
  alias condition condition_rule

  def left_rec(*rules, &act)
    f = proc do |x|
      x[1].inject(x[0]) do |acc, y|
        act.call(Sequence[acc, *y])
      end
    end
    base = rules.shift
    rules.collect { |r| (base - (r * 0)) >> f }.inject(fail) { |acc, r| r | acc }
  end

  alias leftrec left_rec

  def right_rec(*rules, &act)
    f = proc do |x|
      x[0].reverse.inject(x[1]) do |acc, y|
        ys = y.dup
        ys.push(acc)
        act.call(Sequence[*ys])
      end
    end
    base = rules.pop
    rules.collect { |r| ((r * 0) - base) >> f }.inject(fail) { |acc, r| r | acc }
  end

  alias rightrec right_rec

  def chain_left(base, *infixes, &)
    infixes.inject(base) do |acc, r|
      leftrec(acc, r - acc, &)
    end
  end

  alias chainl chain_left

  def chain_right(base, *infixes, &)
    infixes.inject(base) do |acc, r|
      rightrec(acc - r, acc, &)
    end
  end

  alias chainr chain_right

  def self.define(*_args, &)
    klass = Class.new(Grammar)
    g = klass.new
    begin
      if defined?(g.instance_exec)
        g.instance_exec(g, &)
      else
        g.instance_eval(&)
      end
    end
    g
  end
end
