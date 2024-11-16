module TDParser
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
end
