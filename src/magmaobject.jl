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

magmacoerce(a, b) = magmacallf(:!, a, b)
export magmacoerce

magmalength(a) = magmaintconvert(Int, magmacallf(Symbol("#"), a))
export magmalength

function magmagetattr(o::MagmaObject, k::Symbol)
  r = new_magmaobject()
  run_cmd(proc[], name(r), ":=", name(o), '`', k)
  r
end

function magmasetattr(o::MagmaObject, k::Symbol, x)
  x = asobj(x)
  run_cmd(proc[], name(o), '`', k, ":=", name(x))
end

function magmadelattr(o::MagmaObject, k::Symbol)
  run_cmd(proc[], "delete ", name(o), '`', k)
end

function magmaprint(io::IO, o::MagmaObject)
  run_cmd(proc[], "printf \"%o\", ", name(o), on_byte=io)
end

function magmaprintm(io::IO, o::MagmaObject)
  run_cmd(proc[], "printf \"%m\", ", name(o), on_byte=io)
end

