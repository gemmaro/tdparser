require "forwardable"

module TDParser
  class TokenBuffer # :nodoc:
    attr_accessor :map, :state

    def initialize(*args)
      @array = Array.new(args)
      @map = {}
    end

    def [](idx)
      case idx
      when Symbol, String
        @map[idx]
      else
        @array[idx]
      end
    end

    def []=(idx, val)
      case idx
      when Symbol, String
        @map[idx] = val
      else
        @array[idx] = val
      end
    end

    def clear
      @array.clear
      @map.clear
    end

    class << self
      alias [] new
    end

    extend Forwardable
    def_delegators :@array, :each, :unshift, :insert, :reverse, :join, :pop, :push, :to_a
    include Enumerable
  end
end
