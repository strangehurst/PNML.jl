# Bits that are used to build sorts and terms.

"""
    FEConstant
Finite enumeration constant.
In some cases the partition element cannot be derived from the subterms of PartitionElementOf operator.
#~ Ways to locate the partition element: (netid, partition_id), or add parent references.
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol # Id is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    ids::Tuple
    #partid::Symbol #~ is this knowable? part -> sort -> element -> fec VS. sort -> fec
end

(fec::FEConstant)() = fec.name # The value of a FEConstant is its name/identity. Not a `<:Number`.

#TODO Which to do: functor or expression?
#~ functor is an atom
TermInterface.isexpr(op::FEConstant)    = false
TermInterface.iscall(op::FEConstant)    = false # users promise that this is only called if isexpr is true.
TermInterface.head(op::FEConstant)      = :ref # error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.children(op::FEConstant)  = (decldict(first(ids)).feconstants, id) #error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.operation(op::FEConstant) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arguments(op::FEConstant) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arity(op::FEConstant)     = 0
TermInterface.metadata(op::FEConstant)  = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.symtype(op::FEConstant)   = error("NOT IMPLEMENTED: $(typeof(op))")

#:(variabledecls[id]) == maketerm(Expr, :ref, [variabledecls, id])
