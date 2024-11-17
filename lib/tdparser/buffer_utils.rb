module TDParser
  module BufferUtils # :nodoc:
    def prepare(buff)
      b = TokenBuffer.new
      b.map = buff.map
      b
    end

    def recover(buff, ts)
      buff.each { |b| ts.unshift(b) }
    end
  end
end
