module TDParser
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
end
