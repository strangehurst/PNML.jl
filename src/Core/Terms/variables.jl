"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::Symbol
    ids::Tuple # Trail of ids. First is net, used for DeclDict lookups.
end
tag(v::Variable) = v.refvariable
netid(v::Variable) = first(v.ids)
function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin
    println("value(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    @show variable(dd, tag(v))
    return 0 #! XXX FIXME XXX
end
_evaluate(v::Variable) = _evaluate(value(v))

sortof(v::Variable) = begin
    #println("sortof(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    #display(stacktrace())
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    vdecl = variable(dd, tag(v))
    return sortof(vdecl)
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

# Only One
isvariable(tag::Symbol) = tag === :variable
