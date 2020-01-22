import Base: convert

function magmabool(x::Bool)
  o = new_magmaobject()
  unsafe_cmd(proc[], name(o), ":=", x ? "true" : "false")
  o
end
export magmabool

convert(::Type{MagmaObject}, x::Bool) = magmabool(x)

function magmaboolconvert(::Type{Bool}, o::MagmaObject)
  s = magmasprint(o, :m)
  s == "true" ? true : s == "false" ? false : error("error parsing bool")
end
export magmaboolconvert

const stdint = Union{Int8,Int16,Int32,Int64,Int128,UInt8,UInt16,UInt32,UInt64,UInt128,BigInt}

function magmaint(x::stdint)
  o = new_magmaobject()
  unsafe_cmd(proc[], name(o), ":=", x)
  o
end

function magmaint(x::Integer)
  convert(MagmaObject, convert(BigInt, x))
end
export magmaint

convert(::Type{MagmaObject}, x::Integer) = magmaint(x)

function magmaintconvert(::Type{T}, x::MagmaObject) where {T<:stdint}
  s = magmasprint(x, :m)
  parse(T, s)
end
export magmaintconvert


function magmastring(x::AbstractString)
  cs = UInt8[]
  for c in x
    isascii(c) || error("magma only supports ASCII strings")
    if c == '"'
      push!(cs, '\\', '"')
    elseif c == '\\'
      push!(cs, '\\', '\\')
    elseif c == '\n'
      push!(cs, '\\', 'n')
    elseif c == '\r'
      push!(cs, '\\', 'r')
    elseif c == '\t'
      push!(cs, '\\', 't')
    elseif isprint(c)
      push!(cs, c)
    else
      error("magma strings only support printable ASCII")
    end
  end
  ex = String(cs)
  o = new_magmaobject()
  unsafe_cmd(proc[], name(o), ":=\"", ex, '"')
  o
end
export magmastring

convert(::Type{MagmaObject}, x::String) = magmastring(x)

convert(::Type{MagmaObject}, x::AbstractVector) = magmaseq(x)
convert(::Type{MagmaObject}, x::AbstractSet) = magmaset(x)

MagmaObject(x) = convert(MagmaObject, x)
MagmaObject(x::MagmaObject) = x
MagmaObject(x::Symbol) = new_magmaobject(x)
