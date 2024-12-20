# frozen_string_literal: true

require 'tdparser'

module TDParser
  class Token # :nodoc:
    attr_accessor :kind, :value

    def initialize(kind, value)
      @kind = kind
      @value = value
    end

    def ==(other)
      (other.class == self.class) &&
        (@kind == other.kind) &&
        (@value == other.value)
    end

    def ===(other)
      super(other) || (@kind == other)
    end

    def =~(other)
      @kind == other
    end
  end

  class BasicStringTokenizer # :nodoc:
    def self.[](rule, ignore = nil)
      new(rule, ignore)
    end

    def initialize(rule, ignore = nil)
      require('strscan')
      @rule = rule
      @scan_pattern = Regexp.new(@rule.keys.join('|'))
      @ignore_pattern = ignore
    end

    def generate(str)
      scanner = StringScanner.new(str)
      TDParser::TokenGenerator.new do |x|
        until scanner.eos?
          if @ignore_pattern
            while scanner.scan(@ignore_pattern)
            end
          end
          sstr = scanner.scan(@scan_pattern)
          if sstr
            @rule.each do |reg, kind|
              next unless reg =~ sstr

              x.yield(Token.new(kind, sstr))
              break
            end
          else
            c = scanner.scan(/./)
            x.yield(c)
          end
        end
      end
    end
  end

  class StringTokenizer < BasicStringTokenizer
    def initialize(rule, ignore = nil)
      super(rule, ignore || /\s+/)
    end
  end

  class WaitingTokenGenerator < TDParser::TokenGenerator # :nodoc:
    def initialize(*args)
      super(*args)
      @terminated = false
    end

    def terminate
      @terminated = true
    end

    def shift
      return nil if @terminated

      while empty?
      end
      super()
    end
  end
end
