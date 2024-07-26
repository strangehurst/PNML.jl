"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::Symbol
end
tag(v::Variable) = v.refvariable

function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin
    @assert has_variable(PNML.DECLDICT[], tag(v)) "$(tag(v)) not a variable declaration"
    return 0 #! XXX FIXME XXX
end
_evaluate(v::Variable) = _evaluate(value(v))

sortof(v::Variable) = begin
    @assert has_variable(PNML.DECLDICT[], tag(v)) "$(tag(v)) not a variable declaration"
    vdecl = variable(PNML.DECLDICT[], tag(v))
    return sortof(vdecl)
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

# Only One
isvariable(tag::Symbol) = tag === :variable
