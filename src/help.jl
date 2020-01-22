function magmahelp(q::String)
  q = strip(q)
  isempty(q) && (q = "/")
  io = proc[]
  tok = newtoken()
  println(io, "?", q)
  cmd_print_token(io, tok)
  read_to_token(io, tok)
end
export magmahelp

magmahelp() = magmahelp("")
magmahelp(q::Int) = magmahelp(string(q))

