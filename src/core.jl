const magma_executable = "magma"
const proc = Ref{Base.Process}()
const tokenlength = 20
const tokenrange = UInt8('A'):UInt8('Z')

const init_cmd = """
procedure __jl_display(x)
  T := Type(x);
  if ISA(T, MonStgElt) then
    printf "%m", x;
  elif ISA(T, Intrinsic) then
    printf "%m", x;
  else
    printf "%o", x;
  end if;
end procedure;
procedure __jl_propertynames(x)
  T := Type(x);
  if ISA(T, Rec) then
    for n in Names(x) do
      print n;
    end for;
  else
    ListAttributes(T);
  end if;
end procedure;
"""

abstract type MagmaException <: Exception end
abstract type MagmaIOError <: MagmaException end
struct MagmaUnexpectedEOFError <: MagmaIOError end
struct MagmaIOCheckError <: MagmaIOError end
export MagmaException, MagmaIOError, MagmaUnexpectedEOFError, MagmaIOCheckError

function __init__()
  proc[] = open(`$magma_executable -b`, "r+")
  run_cmd(proc[], init_cmd)
end

newtoken() = ntuple(i->rand(tokenrange), Val(tokenlength))

unsafe_cmd(io::IO, args...) =
  println(io, args..., ';')

cmd_print_token(io::IO, tok::Tuple{Vararg{UInt8}}) =
  unsafe_cmd(io, "printf ", '"', map(Char, tok)..., '"')

cmd_delete(io::IO, name) =
  unsafe_cmd(io, "delete ", name)

function read_to_token(io::IO, tok::Tuple{Vararg{UInt8}}; on_byte=stdout, on_eof=MagmaUnexpectedEOFError())
  isempty(tok) && error("token must be non-empty")
  i = 1
  t = @inbounds tok[i]
  while !eof(io)
    x = read(io, UInt8)
    if x == t
      if i ≥ length(tok)
        return
      else
        i += 1
        t = @inbounds tok[i]
      end
    elseif i>1
      for j = 1:i-1
        cb_byte(on_byte, tok[j])
      end
      cb_byte(on_byte, x)
      i = 1
      t = @inbounds tok[i]
    else
      cb_byte(on_byte, x)
    end
  end
  cb(on_eof)
end

cb(::Nothing, args...) = nothing
cb(f::Function, args...) = f(args...)
cb(e::Exception, args...) = throw(e)
cb(e::Type{<:Exception}, args...) = throw(e(args...))

cb_byte(::Nothing, x::UInt8) = nothing
cb_byte(f::Function, x::UInt8) = f(x)
cb_byte(io::IO, x::UInt8) = write(io, x)
cb_byte(e::Exception, x::UInt8) = throw(e)

function check_io(io::IO=proc[])
  tok = newtoken()
  cmd_print_token(io, tok)
  read_to_token(io, tok, on_byte=MagmaIOCheckError())
end

function reset_io(io::IO=proc[])
  tok = newtoken()
  cmd_print_token(io, tok)
  read_to_token(io, tok, on_byte=nothing)
end

function run_cmd_nocatch(io::IO, cmd...; opts...)
  tok = newtoken()
  unsafe_cmd(io, cmd...)
  cmd_print_token(io, tok)
  read_to_token(io, tok; opts...)
end

function run_cmd(io::IO, cmd...; on_success=nothing, on_error=MagmaRuntimeError, opts...)
  # wrap the command in a try block, so that whatever happens, a token is printed out, followed by 0 or 1 depending on whether there was an error
  tok = newtoken()
  unsafe_cmd(io, "try")
  unsafe_cmd(io, cmd...)
  cmd_print_token(io, tok)
  unsafe_cmd(io, "printf \"0\"")
  unsafe_cmd(io, "catch __jltmp")
  unsafe_cmd(io, "__jlerr := __jltmp")
  cmd_print_token(io, tok)
  unsafe_cmd(io, "printf \"1\"")
  unsafe_cmd(io, "end try")
  # read up to the token
  read_to_token(io, tok; opts...)
  # see if there was an error
  x = read(io, UInt8)
  if x == UInt8('0')
    return cb(on_success)
  elseif x == UInt8('1')
    e = new_magmaobject()
    unsafe_cmd(io, name(e), ":=__jlerr")
    unsafe_cmd(io, "delete __jlerr")
    return cb(on_error, e)
  else
    throw(MagmaIOCheckError())
  end
end
