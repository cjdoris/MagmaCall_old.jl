import Base: show, print, length, push!, ==, !=, <, >, ≤, ≥, isequal, isless, isassigned, getproperty, setproperty!, propertynames

function show(io::IO, o::MagmaObject)
  run_cmd(proc[], "printf \"%m\", ", name(o), on_byte=io)
  get(io, :typeinfo, All) <: MagmaObject ||
    print(io, " :: ", MagmaObject)
end

function show(io::IO, ::MIME"text/plain", o::MagmaObject)
  run_cmd(proc[], "__jl_display(", name(o), ')', on_byte=io)
  get(io, :typeinfo, Any) <: MagmaObject ||
    print(io, " :: ", MagmaObject)
end

function print(io::IO, o::MagmaObject)
  run_cmd(proc[], "printf \"%o\", ", name(o), on_byte=io)
end

getproperty(o::MagmaObject, k::Symbol) = magmagetattr(o, k)
setproperty!(o::MagmaObject, k::Symbol, x) = magmasetattr(o, k)
setproperty!(o::MagmaObject, k::Symbol, ::Nothing) = magmadelattr(o, k)

function propertynames(o::MagmaObject)
  io = IOBuffer()
  run_cmd(proc[], "__jl_propertynames(", name(o), ")", on_byte=io)
  map(Symbol, split(strip(read(seekstart(io), String))))
end

for (j,m) in [(:(==), :eq), (:(!=), :ne), (:<, :lt), (:>, :gt), (:(<=), :le), (:(>=), :ge)]
  f = Symbol(:magma,m)
  @eval $f(a, b) = magmaboolconvert(Bool, magmacallf($(QuoteNode(m)), a, b))
  @eval $j(a::MagmaObject, b::MagmaObject) = $f(a,b)
  @eval $j(a::MagmaObject, b) = $f(a,b)
  @eval $j(a, b::MagmaObject) = $f(a,b)
  @eval export $f
end

length(o::MagmaObject) = magmaintconvert(Int, magmacallf(Symbol("#"), o))

function push!(o::MagmaObject, a)
  magmacallp(:Append, Ref(o), a)
  o
end

