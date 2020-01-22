"""
    magmarecformat(name[=>type]...)

Magma record format with field names given by each `name` and optionally types given by each `type`.
"""
@generated function magmarecformat(fields...)
	pre = []
  gcp = []
	flds = []
	for (i,f) in enumerate(fields)
    i == 1 || push!(flds, ',')
	  if f <: Symbol
      push!(flds, :(fields[$i]))
    elseif f <: Pair{Symbol, <:Any}
      n = gensym()
      push!(pre, :($n = asobj(fields[$i][2])))
      push!(gcp, n)
      push!(flds, :(fields[$i][1]), ':', :(name($n)))
    else
      error("bad recformat fields")
    end
	end
	code = quote
		$(pre...)
		o = new_magmaobject()
		Base.GC.@preserve $(gcp...) run_cmd(proc[], name(o), ":=recformat<", $(flds...), '>')
		o
	end
end
export magmarecformat

"""
    magmarec([fmt]; vals...)

Magma record with format `fmt` and values from `vals`.

If `fmt` is not given, a new format with the given names is used.
"""
@generated function magmarec(fmt=Val(:infer); vals...)
  pre = []
  gcp = []
  flds = []
  rflds = []
  jlf = gensym()
  push!(gcp, jlf)
  for (i,v) in enumerate(vals.parameters[4].parameters[1])
    i==1 || push!(flds, ',')
    n = gensym()
    push!(pre, :($n = asobj(vals[$(QuoteNode(v))])))
    push!(gcp, n)
    push!(flds, "$v:=", :(name($n)))
    push!(rflds, QuoteNode(v))
  end
  code = quote
    $(pre...)
    o = new_magmaobject()
    $jlf = $(fmt==Val{:infer} ? :(magmarecformat($(rflds...),)) : :(asobj(fmt)))
    Base.GC.@preserve $(gcp...) run_cmd(proc[], name(o), ":=rec<", name($jlf), '|', $(flds...), '>')
    o
  end
end
export magmarec
