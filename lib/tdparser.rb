# frozen_string_literal: true

# -*- ruby -*-
#
# Top-down parser for embedded in a ruby script.
#

module TDParser
  class ParserException < RuntimeError
  end

  class TokenGenerator
    def initialize(args = nil, &block)
      enumerator = Enumerator.new do |y|
        if args
          args.each { |arg| y << arg }
        else
          block.call(y)
        end
      end
      @enumerator = enumerator

      @buffer = []
    end

    def next
      @enumerator.next
    end

    def next?
      @enumerator.peek
      true
    rescue StopIteration
      false
    end

    def to_a
      @enumerator.to_a
    end

    def shift
      if @buffer.empty?
        (self.next if next?)
      else
        @buffer.shift
      end
    end

    def unshift(*token)
      @buffer.unshift(*token)
    end
  end

  class TokenBuffer < Array
    attr_accessor :map

    def initialize(*args)
      super(*args)
      @map = {}
    end

    def [](idx)
      case idx
      when Symbol, String
        @map[idx]
      else
        super(idx)
      end
    end

    def []=(idx, val)
      case idx
      when Symbol, String
        @map[idx] = val
      else
        super(idx, val)
      end
    end

    def state
      @map[:__state__]
    end

    def state=(s)
      @map[:__state__] = s
    end

    def clear
      super()
      @map.clear
    end
  end

  class Sequence < Array
    def +(other)
      dup.concat(other)
    end
  end

  module BufferUtils
    def prepare(buff)
      b = TokenBuffer.new
      b.map = buff.map
      b
    end

    def recover(buff, ts)
      buff.each { |b| ts.unshift(b) }
    end
  end
  include BufferUtils

  class Parser
    include BufferUtils
    include TDParser

    def to_proc
      proc { |*x| call(*x) }
    end

    def to_s
      '??'
    end

    def call(*args); end

    # def [](*args)
    #  call(*args)
    # end

    def optimize(_default = false)
      dup
    end

    def ==(_other)
      false
    end

    def same?(r)
      self == r
    end

    def -(other)
      ConcatParser.new(self, other)
    end

    def +(other)
      ParallelParser.new(self, other)
    end

    def |(other)
      ChoiceParser.new(self, other).optimize(true)
    end

    def *(other)
      if other.is_a?(Range)
        n = other.min
      else
        n = other
        other = nil
      end
      IterationParser.new(self, n, other)
    end

    def >>(other)
      ActionParser.new(self, other)
    end

    def /(other)
      LabelParser.new(self, other)
    end

    def %(other)
      StackParser.new(self, other)
    end

    def >(other)
      Parser.new do |tokens, buff|
        buff[other] = buff.dup
        self[tokens, buff]
      end
    end

    def ~@
      NegativeParser.new(self)
    end

    def parse(tokens = nil, buff = nil, &blk)
      buff ||= TokenBuffer.new
      @tokens = if blk.nil?
                  if tokens.respond_to?(:shift) && tokens.respond_to?(:unshift)
                    tokens
                  elsif tokens.respond_to?(:each)
                    TokenGenerator.new(tokens)
                  else
                    tokens
                  end
                else
                  TokenGenerator.new(&blk)
                end
      r = call(@tokens, buff)
      if r.nil?
        nil
      else
        r[0]
      end
    end

    def peek
      t = @tokens.shift
      @tokens.unshift(t) unless t.nil?
      t
    end

    def do(&block)
      self >> block
    end
  end
  # end of Parser

  class NonTerminalParser < Parser
    attr_reader :context, :symbol, :options

    def initialize(context, sym, *options)
      @context = context
      @symbol = sym
      @options = options
    end

    def call(tokens, buff)
      res = nil
      case @symbol
      when Symbol, String
        res = @context.__send__(@symbol, *@options).call(tokens, buff)
      when Parser
        res = @symbol.call(tokens, buff)
      end
      res
    end

    def ==(other)
      (self.class == other.class) &&
        (@context == other.context) &&
        (@symbol == other.symbol) &&
        (@options == other.options)
    end

    def to_s
      @symbol.to_s
    end
  end

  class TerminalParser < Parser
    attr_reader :symbol, :equality

    def initialize(obj, eqsym)
      @symbol   = obj
      @equality = eqsym
    end

    def call(tokens, buff)
      t = tokens.shift
      buff.unshift(t)
      return unless @symbol.__send__(@equality, t) || t.__send__(@equality, @symbol)

      Sequence[t]
    end

    def ==(other)
      (self.class == other.class) &&
        (@symbol == other.symbol) &&
        (@equality == other.equality)
    end

    def to_s
      @symbol.to_s
    end
  end

  class CompositeParser < Parser
    attr_accessor :parsers

    def initialize(*parsers)
      @parsers = parsers
    end

    def optimize(default = false)
      parser = dup
      parser.parsers = @parsers.collect { |x| x.optimize(default) }
      parser
    end

    def ==(other)
      (self.class == other.class) &&
        (@parsers == other.parsers)
    end

    def same?(r)
      super(r) &&
        @parsers.zip(r.parsers).all? { |x, y| x.same?(y) }
    end

    def to_s
      "<composite: #{@parsers.collect(&:to_s)}>"
    end
  end

  class ActionParser < CompositeParser
    attr_reader :action

    def initialize(parser, act)
      @action = act
      super(parser)
    end

    def call(tokens, buff)
      if (x = @parsers[0].call(tokens, buff)).nil?
        nil
      else
        x = TokenBuffer[*x]
        x.map = buff.map
        Sequence[@action[x]]
      end
    end

    def ==(other)
      super(other) &&
        (@action == other.action)
    end

    def to_s
      "(#{@parsers[0]} <action>)"
    end
  end

  class LabelParser < CompositeParser
    attr_reader :label

    def initialize(parser, label)
      @label = label
      super(parser)
    end

    def call(tokens, buff)
      x = @parsers[0].call(tokens, buff)
      buff.map[@label] = x
      x
    end

    def ==(other)
      super(other) &&
        (@label == other.label)
    end

    def to_s
      "(#{@parsers[0]}/#{@label})"
    end
  end

  class StackParser < CompositeParser
    attr_reader :stack

    def initialize(parser, stack)
      @stack = stack
      super(parser)
    end

    def call(tokens, buff)
      x = @parsers[0].call(tokens, buff)
      @stack.push(x)
      x
    end

    def ==(other)
      super(other) &&
        (@stack == other.stack)
    end

    def same?(_r)
      false
    end

    def to_s
      "<stack:#{@stack.object_id}>"
    end
  end

  class ConcatParser < CompositeParser
    def call(tokens, buff)
      if (x = @parsers[0].call(tokens, buff)).nil?
        nil
      elsif (y = @parsers[1].call(tokens, buff)).nil?
        nil
      else
        x + y
      end
    end

    def -(other)
      @parsers[0] - (@parsers[1] - other)
    end

    def to_s
      "(#{@parsers[0]} #{@parsers[1]})"
    end
  end

  class ChoiceParser < CompositeParser
    def call(tokens, buff)
      b = prepare(buff)
      if (x = @parsers[0].call(tokens, b)).nil?
        recover(b, tokens)
        @parsers[1].call(tokens, buff)
      else
        buff.insert(0, *b)
        x
      end
    end

    def to_s
      "(#{@parsers[0]} | #{@parsers[1]})"
    end

    def shared_sequence(r1, r2)
      if r1.is_a?(ConcatParser) && r2.is_a?(ConcatParser)
        r11 = r1.parsers[0]
        r12 = r1.parsers[1]
        r21 = r2.parsers[0]
        r22 = r2.parsers[1]
        if r11.same?(r21)
          share, r12, r22, = shared_sequence(r12, r22)
          return [r11 - share, r12, r22] if share

          return [r11, r12, r22]

        end
      end
      [nil, r1, r2]
    end

    def optimize(default = false)
      r1 = @parsers[0]
      r2 = @parsers[1]
      if r1.is_a?(ActionParser)
        act1 = r1.action
        r1 = r1.parsers[0]
      end
      if r2.is_a?(ActionParser)
        act2 = r2.action
        r2 = r2.parsers[0]
      end
      share, r12, r22, = shared_sequence(r1, r2)
      if share
        r = share - (r12 + r22)
        if act1
          r = if act2
                r >> proc do |x|
                  y0, y1, *_ = x.pop
                  if y0
                    act1.call(x.push(*y0))
                  else
                    act2.call(x.push(*y1))
                  end
                end
              else
                r >> proc do |x|
                  y0, = x.pop
                  act1.call(x.push(*y0)) if y0
                end
              end
        elsif act2
          r = r >> proc do |x|
                     _, y1, = x.pop
                     act2.call(x.push(*y1)) if y1
                   end
        end
        return r
      end
      if default
        dup
      else
        super(default)
      end
    end
  end

  class ParallelParser < CompositeParser
    def call(tokens, buff)
      b = prepare(buff)
      if (x = @parsers[0].call(tokens, b)).nil?
        recover(b, tokens)
        Sequence[Sequence[nil, @parsers[1].call(tokens, buff)]]
      else
        buff.insert(0, *b)
        Sequence[Sequence[x, nil]]
      end
    end

    def to_s
      "(#{@parsers[0]} + #{@parsers[1]})"
    end
  end

  class IterationParser < CompositeParser
    attr_reader :min, :range

    def initialize(parser, n, range)
      @min = n
      @range = range
      super(parser)
    end

    def call(ts, buff)
      r = @parsers[0]
      n = @min
      x  = true
      xs = []
      while n.positive?
        n -= 1
        b = prepare(buff)
        if (x = r.call(ts, b)).nil?
          recover(b, ts)
          break
        else
          buff.insert(0, *b)
          xs.push(x)
        end
      end
      if x.nil?
        nil
      else
        if range
          range.each do
            loop do
              y = x
              b = prepare(buff)
              if (x = r.call(ts, b)).nil?
                recover(b, ts)
                x = y
                break
              else
                buff.insert(0, *b)
                xs.push(x)
              end
            end
          end
        else
          loop do
            y = x
            b = prepare(buff)
            if (x = r.call(ts, b)).nil?
              recover(b, ts)
              x = y
              break
            else
              buff.insert(0, *b)
              xs.push(x)
            end
          end
        end
        Sequence[xs]
      end
    end

    def to_s
      "(#{@parsers[0]})*#{@range ? @range.to_s : @min.to_s}"
    end

    def ==(other)
      super(other) &&
        (@min == other.min) &&
        (@range == other.range)
    end
  end

  class NegativeParser < CompositeParser
    def call(tokens, buff)
      b = prepare(buff)
      r = @parsers[0].call(tokens, b)
      rev = b.reverse
      recover(b, tokens)
      return unless r.nil?

      Sequence[Sequence[*rev]]
    end

    def to_s
      "~#{@parsers[0]}"
    end
  end

  class FailParser < Parser
    def call(_tokens, _buff)
      nil
    end

    def to_s
      '<fail>'
    end

    def ==
      (self.class == r.class)
    end
  end

  class EmptyParser < Parser
    def call(_tokens, _buff)
      Sequence[nil]
    end

    def to_s
      '<empty>'
    end

    def ==(_other)
      true
    end
  end

  class AnyParser < Parser
    def call(tokens, _buff)
      t = tokens.shift
      if t.nil?
        nil
      else
        Sequence[t]
      end
    end

    def to_s
      '<any>'
    end

    def ==(_other)
      true
    end
  end

  class NoneParser < Parser
    def call(tokens, _buff)
      t = tokens.shift
      return unless t.nil?

      Sequence[nil]
    end

    def to_s
      '<none>'
    end

    def ==(_other)
      true
    end
  end

  class ReferenceParser < Parser
    private

    def back_ref(xs, eqsym)
      x = xs.shift
      xs.inject(token(x, eqsym)) do |acc, x|
        case x
        when Sequence
          acc - back_ref(x, eqsym)
        else
          acc - token(x, eqsym)
        end
      end
    end

    alias __backref__ back_ref

    def same?(_r)
      false
    end
  end

  class BackrefParser < ReferenceParser
    attr_reader :label, :equality

    def initialize(label, eqsym)
      @label = label
      @equality = eqsym
    end

    def call(tokens, buff)
      ys = buff.map[@label]
      if ys.nil? || ys.empty?
        nil
      else
        back_ref(ys.dup, @equality).call(tokens, buff)
      end
    end

    def to_s
      "<backref:#{@label}>"
    end

    def ==(other)
      super(other) &&
        (@label == other.label) &&
        (@equality == other.equality)
    end
  end

  class StackrefParser < ReferenceParser
    attr_reader :stack, :equality

    def initialize(stack, eqsym)
      @stack = stack
      @equality = eqsym
    end

    def call(tokens, buff)
      ys = @stack.pop
      if ys.nil? || ys.empty?
        nil
      else
        back_ref(ys.dup, @equality).call(tokens, buff)
      end
    end

    def to_s
      "<stackref:#{@stack.object_id}>"
    end

    def ==(other)
      super(other) &&
        @stack.equal?(other.stack) &&
        (@equality == other.equality)
    end
  end

  class ConditionParser < Parser
    attr_reader :condition

    def initialize(&condition)
      @condition = condition
    end

    def call(_tokens, buff)
      return unless (res = @condition.call(buff.map))

      Sequence[res]
    end

    def to_s
      "<condition:#{@condition}>"
    end

    def ==(other)
      super(other) &&
        (@condition == other.condition)
    end

    def same?(_r)
      false
    end
  end

  class StateParser < Parser
    attr_reader :state

    def initialize(s)
      @state = s
    end

    def call(_tokens, buff)
      return unless buff.map[:state] == @state

      Sequence[@state]
    end

    def to_s
      "<state:#{@state}>"
    end

    def ==(other)
      super(other) &&
        (@state == other.state)
    end

    def same?(_r)
      false
    end
  end

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

  def chainl(base, *infixes, &)
    infixes.inject(base) do |acc, r|
      leftrec(acc, r - acc, &)
    end
  end

  def chainr(base, *infixes, &)
    infixes.inject(base) do |acc, r|
      rightrec(acc - r, acc, &)
    end
  end

  class Grammar
    include TDParser

    alias define instance_eval

    def method_missing(sym, *args)
      if sym[-1, 1] == '='
        parser, = args
        name = sym[0..-2]
        parser.is_a?(Parser) or parser = token(parser)
        self.class.instance_eval do
          instance_methods.include?(name.intern) or
            define_method(name) { parser }
        end
      elsif args.empty?
        rule(sym)
      else
        raise(NoMethodError, "undefined method `#{sym}' for #{inspect}")
      end
    end
  end

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
