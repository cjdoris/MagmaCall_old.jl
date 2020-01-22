"""
    magmalist([src])

Magma list, with contents from `src`.
"""
function magmalist()
  o = new_magmaobject()
  unsafe_cmd(proc[], name(o), ":=[**]")
  o
end
export magmalist

function magmalist(xs)
  o = magmalist()
  ro = Ref(o)
  for x in xs
    magmacallp(:Append, ro, x)
  end
  o
end

function magmalist(xs::MagmaObject)
  o = magmalist()
  run_cmd(proc[], "for __jltmp in ", name(xs), " do; Append(~", name(o), ", __jltmp); end for")
  o
end

"""
    magmaseq([src]; [universe])

Magma sequence, with contents from `src` and optional `universe`.
"""
function magmaseq(; universe=nothing)
  o = new_magmaobject()
  if universe===nothing
    unsafe_cmd(proc[], name(o), ":=[]")
  else
    u = asobj(universe)
    unsafe_cmd(proc[], name(o), ":=[", name(u), "|]")
  end
  o
end
export magmaseq

function magmaseq(xs; opts...)
  o = magmaseq(opts...)
  ro = Ref(o)
  for x in xs
    magmacallp(:Append, ro, x)
  end
  o
end

function magmaseq(xs::MagmaObject; opts...)
  o = magmaseq(opts...)
  run_cmd(proc[], "for __jltmp in ", name(xs), " do; Append(~", name(o), ", __jltmp); end for")
  o
end

"""
    magmaset([src]; [universe])

Magma set, with contents from `src` and optional `universe`.
"""
function magmaset(; universe=nothing)
  o = new_magmaobject()
  if universe===nothing
    unsafe_cmd(proc[], name(o), ":={}")
  else
    u = asobj(universe)
    unsafe_cmd(proc[], name(o), ":={", name(u), "|}")
  end
  o
end
export magmaset

function magmaset(xs; opts...)
  o = magmaset(opts...)
  ro = Ref(o)
  for x in xs
    magmacallp(:Include, ro, x)
  end
  o
end

function magmaset(xs::MagmaObject; opts...)
  o = magmaset(opts...)
  run_cmd(proc[], "for __jltmp in ", name(xs), " do; Include(~", name(o), ", __jltmp); end for")
  o
end
