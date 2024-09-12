# TermInterface rewriter stuff

## to_expr

```shell
-*- mode: grep; default-directory: "~/.julia/packages/Metatheory/UymXZ/src/" -*-

grep -nHP 'to_?expr' *.jl 
Metatheory.jl:8:function to_expr end
Patterns.jl:8:import Metatheory: to_expr
Patterns.jl:165:to_expr(x::PatLiteral) = x.value
Patterns.jl:166:to_expr(x::PatVar{T}) where {T} = Expr(:call, :~, Expr(:(::), x.name, x.predicate))
Patterns.jl:167:to_expr(x::PatSegment{T}) where {T<:Function} = Expr(:..., Expr(:call, :~, Expr(:(::), x.name, x.predicate)))
Patterns.jl:168:to_expr(x::PatVar{typeof(alwaystrue)}) = Expr(:call, :~, x.name)
Patterns.jl:169:to_expr(x::PatSegment{typeof(alwaystrue)}) = Expr(:..., Expr(:call, :~, x.name))
Patterns.jl:170:function to_expr(x::PatExpr)
Patterns.jl:172:    maketerm(Expr, :call, [x.quoted_head; to_expr.(arguments(x))], nothing)
Patterns.jl:174:    maketerm(Expr, operation(x), to_expr.(arguments(x)), nothing)
Patterns.jl:178:Base.show(io::IO, pat::AbstractPat) = print(io, to_expr(pat))
Rules.jl:6:using Metatheory.Patterns: to_expr
```
```julia
macro matchable(expr)
  @assert expr.head == :struct
  name = expr.args[2]
  if name isa Expr
    name.head === :(<:) && (name = name.args[1])
    name isa Expr && name.head === :curly && (name = name.args[1])
  end
  fields = filter(x -> x isa Symbol || (x isa Expr && x.head == :(::)), expr.args[3].args)
  get_name(s::Symbol) = s
  get_name(e::Expr) = (@assert(e.head == :(::)); e.args[1])
  fields = map(get_name, fields)

  quote
    $expr # the struct definition
    TermInterface.isexpr(::$name) = true
    TermInterface.iscall(::$name) = true
    TermInterface.head(::$name) = $name
    TermInterface.operation(::$name) = $name
    TermInterface.children(x::$name) = getfield.((x,), ($(QuoteNode.(fields)...),))
    TermInterface.arguments(x::$name) = TermInterface.children(x)
    TermInterface.arity(x::$name) = $(length(fields))
    Base.length(x::$name) = $(length(fields) + 1)
  end |> esc
end
```

maketerm is where the excitement happens, see 
```julia
function TermInterface.maketerm(::Type{<:LambdaExpr}, head, children, metadata = nothing)
  head(children...)
end
```
concrete subtypes of LambdaExpr wrap arguments to constructor

```shell
-*- mode: grep; default-directory: "~/.julia/packages/SymbolicUtils/ZwKM7/src/" -*-

grep -nHP 'to_?expr' *.jl 
code.jl:5:export toexpr, Assignment, (←), Let, Func, DestructuredArgs, LiteralExpr,
code.jl:42:    toexpr(ex, [st,])
code.jl:52:julia> toexpr(a+b)
code.jl:55:julia> toexpr(a+b) |> dump
code.jl:71:To make your own type convertible to Expr using `toexpr` define `toexpr(x, st)` and
code.jl:72:forward the state `st` in internal calls to `toexpr`. `st` is state used to know
code.jl:77:toexpr(x) = toexpr(x, LazyState())
code.jl:98:toexpr(a::Assignment, st) = :($(toexpr(a.lhs, st)) = $(toexpr(a.rhs, st)))
code.jl:115:function function_to_expr(op, O, st)
code.jl:119:    args = map(Base.Fix2(toexpr, st), arguments(O))
code.jl:125:function function_to_expr(op::Union{typeof(*),typeof(+)}, O, st)
code.jl:128:    args = map(Base.Fix2(toexpr, st), sorted_arguments(O))
code.jl:141:function function_to_expr(::typeof(^), O, st)
code.jl:146:            return toexpr(Term(inv, Any[ex]), st)
code.jl:148:            return toexpr(Term(^, Any[Term(inv, Any[ex]), -args[2]]), st)
code.jl:154:function function_to_expr(::typeof(SymbolicUtils.ifelse), O, st)
code.jl:156:    :($(toexpr(args[1], st)) ? $(toexpr(args[2], st)) : $(toexpr(args[3], st)))
code.jl:159:function function_to_expr(x::BasicSymbolic, O, st)
code.jl:163:toexpr(O::Expr, st) = O
code.jl:181:function toexpr(O, st)
code.jl:184:        return issym(O) ? nameof(O) : toexpr(O, st)
code.jl:189:        return toexpr(MakeArray(O, typeof(O)), st)
code.jl:193:    expr′ = function_to_expr(op, O, st)
code.jl:199:        return Expr(:call, toexpr(op, st), map(x->toexpr(x, st), args)...)
code.jl:231:toexpr(x::DestructuredArgs, st) = toexpr(x.name, st)
code.jl:243:    name = toexpr(d, st)
code.jl:268:function toexpr(l::Let, st)
code.jl:297:        return toexpr(Let(assignments, l.body, l.let_block), st)
code.jl:303:    bindings = map(p->toexpr(p, st), dargs)
code.jl:306:                       toexpr(l.body, st)) : Expr(:block,
code.jl:308:                                                  toexpr(l.body, st))
code.jl:348:julia> toexpr(func)
code.jl:364:julia> executable = eval(toexpr(func))
code.jl:373:toexpr_kw(f, st) = Expr(:kw, toexpr(f, st).args...)
code.jl:375:function toexpr(f::Func, st)
code.jl:385:        :(function ($(map(x->toexpr(x, st), f.args)...),)
code.jl:387:              $(toexpr(body, st))
code.jl:390:        :(function ($(map(x->toexpr(x, st), f.args)...),;
code.jl:391:                    $(map(x->toexpr_kw(x, st), f.kwargs)...))
code.jl:393:              $(toexpr(body, st))
code.jl:424:function toexpr(a::AtIndex, st)
code.jl:425:    toexpr(a.elem, st)
code.jl:428:function toexpr(s::SetArray, st)
code.jl:430:        $([:($(toexpr(s.arr, st))[$(ex isa AtIndex ? ex.i : i)] = $(toexpr(ex, st)))
code.jl:474:function toexpr(a::MakeArray, st)
code.jl:475:    similarto = toexpr(a.similarto, st)
code.jl:484:                     $(map(x->toexpr(x, st), a.elems)...),)
code.jl:617:function toexpr(a::MakeSparseArray{<:SparseMatrixCSC}, st)
code.jl:621:                      [$(toexpr.(sp.nzval, (st,))...)]))
code.jl:624:function toexpr(a::MakeSparseArray{<:SparseVector}, st)
code.jl:628:                   [$(toexpr.(sp.nzval, (st,))...)]))
code.jl:642:function toexpr(a::MakeTuple, st)
code.jl:643:    :(($(toexpr.(a.elems, (st,))...),))
code.jl:671:function toexpr(p::SpawnFetch{Multithreaded}, st)
code.jl:674:        :(Base.Threads.@spawn $(toexpr(thunk, st))($(toexpr.(xs, (st,))...)))
code.jl:677:        $(toexpr(p.combine, st))(map(fetch, ($(spawns...),))...)
code.jl:684:Literally `ex`, an `Expr`. `toexpr` on `LiteralExpr` recursively calls
code.jl:685:`toexpr` on any interpolated symbolic expressions.
code.jl:692:recurse_expr(ex, st) = toexpr(ex, st)
code.jl:694:function toexpr(exp::LiteralExpr, st)
```
