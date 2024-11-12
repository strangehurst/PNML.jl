# boolean sort operators

"""
    BooleanConstant("true"|"false")
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

function BooleanConstant(s::Union{AbstractString,SubString{String}})
    s == "true" || s == "false" || throw(ArgumentError("BooleanConstant unexpected value $s"))
    BooleanConstant(parse(eltype(BoolSort), s))
end
tag(::BooleanConstant) = :booleanconstant
sortref(::BooleanConstant) = usersort(:bool)::UserSort # usersort,namedsort duo
sortof(::BooleanConstant) = sortdefinition(namedsort(:bool)) # usersort,namedsort duo

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = bc.value
toexpr(c::BooleanConstant) = value(c)
