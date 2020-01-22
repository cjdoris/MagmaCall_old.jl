"""
  STDLIB :: Vector{Tuple}

Each element defines the signature of an intrinsic. It is a tuple with three entries:
- The name of the intrinsic, as a Symbol
- The number of arguments, or `*` for any number, or a tuple of arguments where each element is `~` for references and `*` for ordinary values.
- The number of return values (0 for procedures)

This is used to create corresponding julia functions `magma_<name>`, and possibly also `magma_<name>!` if there are any reference arguments.
"""
const STDLIB = [
	(:Universe, 1, 1),
  (:Type, 1, 1),
  (:ExtendedType, 1, 1),
  (:ISA, 2, 1),
  (:Append, 2, 1),
  (:Append, (~, *), 0),
  (:Include, 2, 1),
  (:Include, (~, *), 0),
  (:Integers, *, 1),
  (:IntegerRing, *, 1),
  (:Rationals, *, 1),
  (:RationalField, *, 1),
  (:PolynomialRing, *, 1),
  (:RealField, *, 1),
  (:ComplexField, *, 1),
  (:FiniteField, *, 1),
  (:pAdicField, *, 1),
  (:AssignNames, (~,*), 0),
  (:Names, *, 1),
  (:Name, *, 1),
  (:Sort, 1, 1),
  (:Sort, 2, 2),
  (:Sort, (~,), 0),
  (:Sort, (~,*), 0),
  (:Sort, (~,*,~), 0),
  (:Random, *, 1),
]

function declare_intrinsic(mdl, n, a, r; prefix=:magma_, doexport=true, dorefs=true)
  f = Symbol(prefix, n)
  # parse the argument specifier `a`
  refs = Set{Int}()
  if a isa Integer
    iargs = cargs = [gensym() for i in 1:a]
  elseif a === *
    iargs = cargs = [:(args...)]
  elseif a isa Tuple
    iargs = []
    cargs = []
    for (i,t) in enumerate(a)
      x = gensym()
      if t === ~
        push!(refs, i)
        push!(iargs, :($x :: Ref{<:MagmaObject}))
        push!(cargs, x)
      elseif t === *
        push!(iargs, x)
        push!(cargs, x)
      else
        error("bad args")
      end
    end
  else
    error("bad args")
  end
  # define the function end export it
  @eval mdl $f($(iargs...); opts...) = magmacall($(Val(r)), $(QuoteNode(n)), $(cargs...); opts...)
  doexport && @eval mdl export $f
  # if it has any ref arguments, also define a modifying version with ! appended to the name
  if dorefs && !isempty(refs)
    f2 = Symbol(f, :!)
    iargs2 = []
    cargs2 = []
    for (i,(ia,ca)) in enumerate(zip(iargs, cargs))
      if i in refs
        x = gensym()
        push!(iargs2, x)
        push!(cargs2, :(Ref($x)))
      else
        push!(iargs2, ia)
        push!(cargs2, ca)
      end
    end
    @eval mdl $f2($(iargs2...); opts...) = magmacall($(Val(r)), $(QuoteNode(n)), $(cargs2...); opts...)
    doexport && @eval mdl export $f2
  end
end

for x in STDLIB
  declare_intrinsic(@__MODULE__, x...)
end