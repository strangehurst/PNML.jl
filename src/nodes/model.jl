"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets.
"""
mutable struct PnmlModel
    nets::Tuple{Vararg{PnmlNet}} # Holds concrete subtypes.
    namespace::String
end

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = model.nets
namespace(model::PnmlModel) = model.namespace

"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as symbol or pnmltype singleton.
"""
function find_nets end
find_nets(model, str::AbstractString) = find_nets(model, PnmlTypeDefs.pntd_symbol(str))
find_nets(model, sym::Symbol)    = find_nets(model, pnmltype(sym))
find_nets(model, net::PnmlNet)   = find_nets(model, pntd(net))
find_nets(model, pntd::PnmlType) = Iterators.filter(n -> Fix1(===, pntd)(nettype(n)), nets(model))

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing``.
"""
function find_net(model, id::Symbol)
    for net in nets(model)
        ispid(id)(pid(net)) && return net
    end
    return nothing
end

# No indent done here.
function Base.show(io::IO, model::PnmlModel)
    print(io, "PnmlModel(", namespace(model), ", ",)
    println(io, length(nets(model)), " nets:" )
    for (i, net) in enumerate(nets(model))
        show(io, net)
        if i < length(nets(model))
            println(io)
        end
    end
end
