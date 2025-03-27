# boolean sort operators

"""
    BooleanConstant("true"|"false") is a built-in operator (constants are 0-ary operators).
    c = BooleanConstant(true); c() == true
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

function BooleanConstant(s::Union{AbstractString,SubString{String}})
    BooleanConstant(parse(eltype(sortdefinition(namedsort(:bool))), s))
end

tag(::BooleanConstant) = :booleanconstant
sortref(::BooleanConstant) = usersort(:bool)::UserSort # usersort,namedsort duo
sortof(::BooleanConstant) = sortdefinition(namedsort(:bool)) # usersort,namedsort duo

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = bc.value
toexpr(c::BooleanConstant, ::NamedTuple) = value(c)
