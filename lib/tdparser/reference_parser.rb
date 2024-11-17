module TDParser
  class ReferenceParser < Parser # :nodoc:
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
end
