module TDParser
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
end
