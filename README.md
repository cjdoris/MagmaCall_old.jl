# MagmaCall.jl

Call Magma code from Julia.

## Installation

Install: `using Pkg; Pkg.add("https://github.com/cjdoris/MagmaCall.jl")`

Currently `magma` must be in your `PATH`.

## User Guide

### Basics

A Magma value is represented as a `MagmaObject`. Basic types can be converted directly:

```julia
julia> MagmaObject(true)
true :: MagmaObject

julia> MagmaObject("foo")
"foo" :: MagmaObject

julia> MagmaObject([1,2,3])
[ 1, 2, 3 ] :: MagmaObject
```

Symbols are interpreted as variable names in the Magma interpreter:
```julia
julia> MagmaObject(:Integers)
'Integers' :: MagmaObject

julia> MagmaObject(:RngIntElt)
RngIntElt :: MagmaObject
```

Julia syntax is converted to the corresponding Magma syntax, so you can do arithmetic, comparisons, attribute lookup (i.e. `x.k` is translated to ```x`k```), indexing, etc.

### Function calls

Use `magmacall(N, f, ...; ...)` to call the Magma function/procedure `f` with the given arguments and optional arguments. The first argument `N` is the number of return values:
- if `N=0` then `f` is assumed to be a procedure, return `nothing`;
- if `N=1` then `f` is assumed to be a function, return its (first) argument;
- otherwise, return its first `N` arguments as a tuple.

There are shorthands `magmacallX(f, ...; ...)` where `X=p` for `N=0`, `X=f` for `N=1` and `X=fN` for `N>1`.

If `f` is a `MagmaObject` then you can instead call `f(N, ...; ...)`.

```julia
julia> magmacallf(:Integers)
Integer Ring :: MagmaObject
```

### Containers

Sequences, sets, lists etc. can be created like so:
```julia
julia> x = magmaseq()
[] :: MagmaObject

julia> magmacallf(:HasUniverse, x)
false :: MagmaObject

julia> x = magmaset(universe = magmacallf(:Integers))
{} :: MagmaObject

julia> magmacallf(:Universe, x)
Integer Ring :: MagmaObject
```

Similarly one can create and manipulate records:
```julia
julia> f = magmarecformat(:foo, :bar)
recformat<foo, bar> :: MagmaObject

julia> x = magmarec(f, foo=99)
rec<recformat<foo, bar> | 
foo := 99> :: MagmaObject

julia> x.bar = 12
12

julia> x.foo = nothing

julia> x
rec<recformat<foo, bar> | 
bar := 12> :: MagmaObject
```