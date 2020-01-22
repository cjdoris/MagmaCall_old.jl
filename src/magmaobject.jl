const currentid = Ref(0)

nextid() = currentid[] += 1

mutable struct MagmaObject{T}
  id :: T
  MagmaObject(::Val{:new}, id::T) where {T<:Union{Int,Symbol}} = new{T}(id)
end
export MagmaObject

unsafe_new_magmaobject(x) = MagmaObject(Val(:new), x)

new_magmaobject(x::Symbol) = unsafe_new_magmaobject(x)

function new_magmaobject(x::Int=nextid())
  o = unsafe_new_magmaobject(x)
  unsafe_cmd(proc[], name(o), ":=0")
  finalizer(o->cmd_delete(proc[], name(o)), o)
  o
end

# isassigned(o::MagmaObject{Int}) = true
# function isassigned(o::MagmaObject{Symbol})
#   tmp = new_magmaobject()
#   unsafe_cmd(proc[], name(tmp), ":=assigned ", name(o))
#   magmaboolconvert(Bool, tmp)
# end

id(o::MagmaObject) = getfield(o, :id)

name(o::MagmaObject{Int}) = Symbol(:__jlvar_, id(o))
name(o::MagmaObject{Symbol}) = Symbol("'", id(o), "'")

asobj(o) = MagmaObject(o)

objname(o::MagmaObject) = name(o)

asarg(o) = asobj(o)
asarg(o::Ref{<:MagmaObject}) = o

argname(o) = objname(o)
argname(o::Ref{<:MagmaObject}) = "~$(objname(o[]))"

struct MagmaRuntimeError <: MagmaException
  err :: MagmaObject{Int}
end
export MagmaRuntimeError

function Base.showerror(io::IO, e::MagmaRuntimeError)
  println(io, "MagmaRuntimeError:")
  print(io, e.err)
end

"""
    magmasprint(o, [fmt=:o])

Convert `o` to a `String` in the given format.
"""
function magmasprint(o::MagmaObject, fmt=:o)
  io = IOBuffer()
  run_cmd(proc[], "printf \"%", fmt, "\", ", name(o), on_byte=io)
  read(seekstart(io), String)
end
export magmasprint

magmacoerce(a, b) = magmacallf(:!, a, b)

