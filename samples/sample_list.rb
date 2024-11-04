require 'tdp'

parser = TDParser.define{|g|
  g.lp = "("
  g.rp = ")"
  g.str = /\w+/

  # Note that "g.elem*1" is a iteration of a sequence that consists
  # of only "g.elem", but it is not a iteration of "g.elem".
  g.list = g.lp - g.elem*1 - g.rp >> proc{|x| x[1].collect{|y| y[0]} }
  g.elem = (g.str | g.list) >> proc{|x| x[0]}

  def parse(str)
    buff = str.split(/\s+|([\(\)])/).select{|s| s.size() > 0}
    list.parse(buff)
  end
}

list = "(a (b c d) (e f g))"
r = parser.parse(list)
p r
