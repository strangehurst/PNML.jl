"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::REFID
    declarationdicts::DeclDict

    function Variable(v::REFID, ddict)
        # Check that REFID is valid in DeclDict.
        PNML.has_variabledecl(ddict, v) || throw(ArgumentError("$(v) not a variable reference ID"))
        new(v, ddict)
    end
end

refid(v::Variable) = v.refvariable
decldict(v::Variable) = v.declarationdicts

function (var::Variable)()
    value(var)
end
value(v::Variable) = error("not well defined: value($v)") #! XXX FIXME XXX

sortref(v::Variable) = sortref(variabledecl(ddict, refid(v)))::SortRef # Access variabledecl in decldicts
sortof(v::Variable)  = sortof(variabledecl(ddict, refid(v)))  # Access variabledecl in decldicts

function Base.show(io::IO, v::Variable)
    print(io, nameof(typeof(v)), "(", repr(v.refvariable), ")")
end
