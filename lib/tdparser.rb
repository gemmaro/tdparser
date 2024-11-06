# frozen_string_literal: true

# -*- ruby -*-
#
# Top-down parser for embedded in a ruby script.
#

module TDParser
  class TokenGenerator
    def initialize(args = nil, &block)
      @enumerator = Enumerator.new do |y|
        if args
          args.each { |arg| y << arg }
        else
          block.call(y)
        end
      end

      @buffer = []
    end

    def next
      @enumerator.next
    end

    def next?
      begin
        @enumerator.peek
        true
      rescue StopIteration
        false
      end
    end

    def to_a
      @enumerator.to_a
    end

    def shift
      if  @buffer.empty?
        if  self.next?
          token = self.next
        else
          token = nil
        end
      else
        token = @buffer.shift
      end
      token
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
    def +(seq)
      self.dup.concat(seq)
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
      Proc.new { |*x| self.call(*x) }
    end

    def to_s
      "??"
    end

    def call(*args)
    end

    #def [](*args)
    #  call(*args)
    #end

    def optimize(_default = false)
      self.dup
    end

    def ==(_r)
      false
    end

    def same?(r)
      self == r
    end

    def -(r)
      ConcatParser.new(self, r)
    end

    def +(r)
      ParallelParser.new(self, r)
    end

    def |(r)
      ChoiceParser.new(self, r).optimize(true)
    end

    def *(range)
      if  range.is_a?(Range)
        n = range.min
      else
        n = range
        range = nil
      end
      IterationParser.new(self, n, range)
    end

    def >>(act)
      ActionParser.new(self, act)
    end

    def /(label)
      LabelParser.new(self, label)
    end

    def %(stack)
      StackParser.new(self, stack)
    end

    def >(symbol)
      Parser.new { |tokens, buff|
        buff[symbol] = buff.dup
        self[tokens, buff]
      }
    end

    def ~@
      NegativeParser.new(self)
    end

    def parse(tokens = nil, buff = nil, &blk)
      buff ||= TokenBuffer.new
      if  blk.nil?
        if ( tokens.respond_to?(:shift) && tokens.respond_to?(:unshift) )
          @tokens = tokens
        elsif  tokens.respond_to?(:each)
          @tokens = TokenGenerator.new(tokens)
        else
          @tokens = tokens
        end
      else
        @tokens = TokenGenerator.new(&blk)
      end
      r = call(@tokens, buff)
      if  r.nil?
        nil
      else
        r[0]
      end
    end

    def peek
      t = @tokens.shift
      if  ! t.nil?
        @tokens.unshift(t)
      end
      t
    end

    def do(&block)
        self >> block
    end
  end
  # end of Parser

  class NonTerminalParser < Parser # :nodoc:
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

    def ==(r)
      (self.class == r.class) &&
      (@context == r.context) &&
      (@symbol == r.symbol) &&
      (@options == r.options)
    end

    def to_s
      "#{@symbol}"
    end
  end

  class TerminalParser < Parser # :nodoc:
    attr_reader :symbol, :equality

    def initialize(obj, eqsym)
      @symbol   = obj
      @equality = eqsym
    end

    def call(tokens, buff)
      t = tokens.shift
      buff.unshift(t)
      if ( @symbol.__send__(@equality, t) || t.__send__(@equality, @symbol) )
        Sequence[t]
      else
        nil
      end
    end

    def ==(r)
      (self.class == r.class) &&
      (@symbol == r.symbol) &&
      (@equality == r.equality)
    end

    def to_s
      "#{@symbol}"
    end
  end

  class CompositeParser < Parser # :nodoc:
    attr_accessor :parsers

    def initialize(*parsers)
      @parsers = parsers
    end

    def optimize(default = false)
      parser = dup
      parser.parsers = @parsers.collect { |x| x.optimize(default) }
      parser
    end

    def ==(r)
      (self.class == r.class) &&
      (@parsers == r.parsers)
    end

    def same?(r)
      super(r) &&
      @parsers.zip(r.parsers).all? { |x, y| x.same?(y) }
    end

    def to_s
      "<composite: #{@parsers.collect { |x| x.to_s }}>"
    end
  end

  class ActionParser < CompositeParser # :nodoc:
    attr_reader :action

    def initialize(parser, act)
      @action = act
      super(parser)
    end

    def call(tokens, buff)
      if  (x = @parsers[0].call(tokens, buff)).nil?
        nil
      else
        x = TokenBuffer[*x]
        x.map = buff.map
        Sequence[@action[x]]
      end
    end

    def ==(r)
      super(r) &&
      (@action == r.action)
    end

    def to_s
      "(#{@parsers[0]} <action>)"
    end
  end

  class LabelParser < CompositeParser # :nodoc:
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

    def ==(r)
      super(r) &&
      (@label == r.label)
    end

    def to_s
      "(#{@parsers[0]}/#{@label})"
    end
  end

  class StackParser < CompositeParser # :nodoc:
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

    def ==(r)
      super(r) &&
      (@stack == r.stack)
    end

    def same?(_r)
      false
    end

    def to_s
      "<stack:#{@stack.object_id}>"
    end
  end

  class ConcatParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      if  (x = @parsers[0].call(tokens, buff)).nil?
        nil
      else
        if  (y = @parsers[1].call(tokens, buff)).nil?
          nil
        else
          x + y
        end
      end
    end

    def -(r)
      @parsers[0] - (@parsers[1] - r)
    end

    def to_s
      "(#{@parsers[0]} #{@parsers[1]})"
    end
  end

  class ChoiceParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      b = prepare(buff)
      if  (x = @parsers[0].call(tokens, b)).nil?
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
      if (r1.is_a?(ConcatParser) && r2.is_a?(ConcatParser))
        r11 = r1.parsers[0]
        r12 = r1.parsers[1]
        r21 = r2.parsers[0]
        r22 = r2.parsers[1]
        if r11.same?(r21)
          share, r12, r22, = shared_sequence(r12, r22)
          if share
            return [r11 - share, r12, r22]
          else
            return [r11, r12, r22]
          end
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
          if act2
            r = r >> Proc.new { |x|
              y0, y1, = x.pop
              if y0
                act1.call(x.push(*y0))
              else
                act2.call(x.push(*y1))
              end
            }
          else
            r = r >> Proc.new { |x|
              y0, = x.pop
              if y0
                act1.call(x.push(*y0))
              end
            }
          end
        else
          if act2
            r = r >> Proc.new { |x|
              _, y1, = x.pop
              if y1
                act2.call(x.push(*y1))
              end
            }
          end
        end
        return r
      end
      if default
        self.dup
      else
        super(default)
      end
    end
  end

  class ParallelParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      b = prepare(buff)
      if  (x = @parsers[0].call(tokens, b)).nil?
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

  class IterationParser < CompositeParser # :nodoc:
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
      while ( n > 0 )
        n -= 1
        b = prepare(buff)
        if  (x = r.call(ts, b)).nil?
          recover(b, ts)
          break
        else
          buff.insert(0, *b)
          xs.push(x)
        end
      end
      if  x.nil?
        nil
      else
        if  range
          range.each {
            while  true
              y = x
              b = prepare(buff)
              if  (x = r.call(ts, b)).nil?
                recover(b, ts)
                x = y
                break
              else
                buff.insert(0, *b)
                xs.push(x)
              end
            end
          }
        else
          while  true
            y = x
            b = prepare(buff)
            if  (x = r.call(ts, b)).nil?
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

    def ==(r)
      super(r) &&
      (@min == r.min) &&
      (@range == r.range)
    end
  end

  class NegativeParser < CompositeParser # :nodoc:
    def call(tokens, buff)
      b = prepare(buff)
      r = @parsers[0].call(tokens, b)
      rev = b.reverse
      recover(b, tokens)
      if  r.nil?
        Sequence[Sequence[*rev]]
      else
        nil
      end
    end

    def to_s
      "~#{@parsers[0]}"
    end
  end

  class FailParser < Parser # :nodoc:
    def call(_tokens, _buff)
      nil
    end

    def to_s
      "<fail>"
    end

    def ==
      (self.class == r.class)
    end
  end

  class EmptyParser < Parser # :nodoc:
    def call(_tokens, _buff)
      Sequence[nil]
    end

    def to_s
      "<empty>"
    end

    def ==(_r)
      true
    end
  end

  class AnyParser < Parser # :nodoc:
    def call(tokens, _buff)
      t = tokens.shift
      if t.nil?
        nil
      else
        Sequence[t]
      end
    end

    def to_s
      "<any>"
    end

    def ==(_r)
      true
    end
  end

  class NoneParser < Parser # :nodoc:
    def call(tokens, _buff)
      t = tokens.shift
      if t.nil?
        Sequence[nil]
      else
        nil
      end
    end

    def to_s
      "<none>"
    end

    def ==(_r)
      true
    end
  end

  class ReferenceParser < Parser # :nodoc:
    def __backref__(xs, eqsym)
      x = xs.shift
      xs.inject(token(x, eqsym)) { |acc, x|
        case x
        when Sequence
          acc - __backref__(x, eqsym)
        else
          acc - token(x, eqsym)
        end
      }
    end

    def same?(_r)
      false
    end
  end

  class BackrefParser < ReferenceParser # :nodoc:
    attr_reader :label, :equality

    def initialize(label, eqsym)
      @label = label
      @equality  = eqsym
    end

    def call(tokens, buff)
      ys = buff.map[@label]
      if (ys.nil? || ys.empty?)
        nil
      else
        __backref__(ys.dup, @equality).call(tokens, buff)
      end
    end

    def to_s
      "<backref:#{@label}>"
    end

    def ==(r)
      super(r) &&
      (@label == r.label) &&
      (@equality == r.equality)
    end
  end

  class StackrefParser < ReferenceParser # :nodoc:
    attr_reader :stack, :equality

    def initialize(stack, eqsym)
      @stack = stack
      @equality = eqsym
    end

    def call(tokens, buff)
      ys = @stack.pop
      if (ys.nil? || ys.empty?)
        nil
      else
        __backref__(ys.dup, @equality).call(tokens, buff)
      end
    end

    def to_s
      "<stackref:#{@stack.object_id}>"
    end

    def ==(r)
      super(r) &&
      @stack.equal?(r.stack) &&
      (@equality == r.equality)
    end
  end

  class ConditionParser < Parser # :nodoc:
    attr_reader :condition

    def initialize(&condition)
      @condition = condition
    end

    def call(_tokens, buff)
      if (res = @condition.call(buff.map))
        Sequence[res]
      else
        nil
      end
    end

    def to_s
      "<condition:#{@condition}>"
    end

    def ==(r)
      super(r) &&
      (@condition == r.condition)
    end

    def same?(_r)
      false
    end
  end

  class StateParser < Parser # :nodoc:
    attr_reader :state

    def initialize(s)
      @state = s
    end

    def call(_tokens, buff)
      if (buff.map[:state] == @state)
        Sequence[@state]
      else
        nil
      end
    end

    def to_s
      "<state:#{@state}>"
    end

    def ==(r)
      super(r) &&
      (@state == r.state)
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

  def backref(x, eqsym = :===)
    BackrefParser.new(x, eqsym)
  end

  def stackref(stack, eqsym = :===)
    StackrefParser.new(stack, eqsym)
  end

  def state(s)
    StateParser.new(s)
  end

  def empty_rule(&b)
    EmptyParser.new(&b)
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

  def condition_rule(&b)
    ConditionParser.new(&b)
  end
  alias condition condition_rule

  def leftrec(*rules, &act)
    f = Proc.new { |x|
      x[1].inject(x[0]) { |acc, y|
        act.call(Sequence[acc, *y])
      }
    }
    base = rules.shift
    rules.collect { |r| (base - (r * 0)) >> f }.inject(fail) { |acc, r| r | acc }
  end

  def rightrec(*rules, &act)
    f = Proc.new { |x|
      x[0].reverse.inject(x[1]) { |acc, y|
        ys = y.dup
        ys.push(acc)
        act.call(Sequence[*ys])
      }
    }
    base = rules.pop
    rules.collect { |r| ((r * 0) - base) >> f }.inject(fail) { |acc, r| r | acc }
  end

  def chainl(base, *infixes, &act)
    infixes.inject(base) { |acc, r|
      leftrec(acc, r - acc, &act)
    }
  end

  def chainr(base, *infixes, &act)
    infixes.inject(base) { |acc, r|
      rightrec(acc - r, acc, &act)
    }
  end

  class Grammar
    include TDParser

    def define(&block)
      instance_eval {
        begin
          alias method_missing g_method_missing
          block.call(self)
        end
      }
    end

    def g_method_missing(sym, *args)
      arg0 = args[0]
      sym = sym.to_s
      if (sym[-1, 1] == "=")
        name = sym[0..-2]
        case arg0
        when Parser
          self.class.instance_eval {
            method_defined?(name) or
              define_method(name) { arg0 }
          }
        else
          t = token(arg0)
          self.class.instance_eval {
            method_defined?(name) or
            define_method(name) { t }
          }
        end
      elsif (args.size == 0)
        rule(sym)
      else
        raise(NoMethodError, "undefined method `#{sym}' for #{self.inspect}")
      end
    end

    alias method_missing g_method_missing
  end

  def TDParser.define(*_args, &block)
    klass = Class.new(Grammar)
    g = klass.new
    begin
      if defined?(g.instance_exec)
        g.instance_exec(g, &block)
      else
        g.instance_eval(&block)
      end
    end
    g
  end
end
