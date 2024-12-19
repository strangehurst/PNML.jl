"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::REFID
    #TODO reference to marking here or in declaration object?
    function Variable(v::REFID)
        # Check that REFID is valid in DECLDICT[].
        has_variabledecl(v) || throw(ArgumentError("$(v) not a variable reference ID"))
        new(v)
    end
end

refid(v::Variable) = v.refvariable

function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin #! XXX FIXME XXX
    return 0
end
_evaluate(v::Variable) = begin println("_evaluate: variable $(refid(v))"); _evaluate(value(v)); end #! dynamic expression, term rewrite, firing rule

sortref(v::Variable) = sortref(variable(refid(v)))::UserSort # Access variabledecl in decldicts
sortof(v::Variable)  = sortof(variable(refid(v)))  # Access variabledecl in decldicts
