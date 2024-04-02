"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets and an ID Registries.
"""
struct PnmlModel
    nets::Tuple{Vararg{PnmlNet}} # Holds concrete subtypes.
    namespace::String
    regs::Vector{PnmlIDRegistry} # Same size as nets. Registries may alais.
end
#TODO mutable PnmlModel, nets, regs as Vector{Any}, Global variable to access declarations
#TODO Is there a need to access declarations (DeclDict) during parsing?
#TODO Will declarations be parsed first? What needs this access?
#TODO Use of IDs decouples (possibly).
#foo::RefValue{Vector{Any}} = RefValue{Vector{Any}}()
#foo[] = [1.123]

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = model.nets
regs(model::PnmlModel) = model.regs
namespace(model::PnmlModel) = model.namespace
netsets(_::PnmlModel)  = throw(ArgumentError("`PnmlModel` does not have a PnmlKeySet, did you want a `Page`?"))

ispnmltype(pntd::PnmlType) = Fix1(===, pntd)

"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as symbol or pnmltype singleton.
"""
function find_nets end
find_nets(model, str::AbstractString) = find_nets(model, pntd_symbol(str))
find_nets(model, sym::Symbol)    = find_nets(model, pnmltype(sym))
find_nets(model, pntd::PnmlType) = Iterators.filter(n -> Fix1(===, pntd)(pnmltype(n)), nets(model))

find_nets(model, ::Type{T}) where {T<:PnmlType} = Iterators.filter(n -> Fix2(isa, T)(nettype(n)), nets(model))

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing``.
"""
function find_net end

function find_net(model, id::Symbol)
    for net in nets(model)
        ispid(id)(pid(net)) && return net
    end
    return nothing
end

# No indent done here.
function Base.show(io::IO, model::PnmlModel)
    print(io, "PnmlModel(")
    show(io, namespace(model)); print(io, ", ",)
    println(io, length(nets(model)), " nets:" )

    for (i, net) in enumerate(nets(model))
        show(io, net)
        if i < length(nets(model))
            println(io)
        end
    end
    print(io, ")")
    #PnmlIDRegistry
end
