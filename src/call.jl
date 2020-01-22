@generated function magmacall(::Val{N}, f, args...; opts...) where {N}
  optnames = opts.parameters[4].parameters[1]
  jlfname = gensym()
  jlargnames = [gensym() for a in args]
  jloptnames = [gensym() for o in optnames]
  jlretnames = [gensym() for i in 1:N]
  cmd = []
  if N>0
    for (i,n) in enumerate(jlretnames)
      i==1 || push!(cmd, ',')
      push!(cmd, :(objname($n)))
    end
    push!(cmd, ":=")
  end
  push!(cmd, :(name($jlfname)), '(')
  for (i,n) in enumerate(jlargnames)
    i==1 || push!(cmd, ',')
    push!(cmd, :(argname($n)))
  end
  for (i,(n,m)) in enumerate(zip(jloptnames, optnames))
    push!(cmd, i==1 ? ':' : ',', m, ":=", :(objname($n)))
  end
  push!(cmd, ')')
  code = quote
    $jlfname = asobj(f)
    $([:($n = asarg(args[$i])) for (i,n) in enumerate(jlargnames)]...)
    $([:($n = asobj(opts[$(QuoteNote(o))])) for (n,o) in zip(jloptnames, optnames)]...)
    $([:($n = new_magmaobject()) for n in jlretnames]...)
    Base.GC.@preserve $([jlfname; jlargnames; jloptnames]...) run_cmd(proc[], $(cmd...))
    $(N==0 ? :(return) : N==1 ? :(return $(jlretnames[1])) : :(return ($(jlretnames...),)))
  end
end
export magmacall

magmacall(N::Int, f, args...; opts...) = magmacall(Val(N), f, args...; opts...)

for N in 0:10
  f = N==0 ? :magmacallp : N==1 ? :magmacallf : Symbol(:magmacallf, N)
  @eval $f(f, args...; opts...) = magmacall($(Val(N)), f, args...; opts...)
  @eval export $f
end

(f::MagmaObject)(N::Union{Val,Int}, args...; opts...) = magmacall(N, f, args...; opts...)
