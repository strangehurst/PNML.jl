"""
    PnmlTuple

PnmlTuples have a similarity to NamedTuples with Sorts taking the place of names.
Will not achieve the same transparancy and efficency as NamedTuples.
NB: NamedTuples uses Symbols where PnmlTuple uses Sorts (must be made bitstype

#! Use tuple of sort REFID symbols as the names of a named tuple.
"""
struct PnmlTuple{sorts, T} where {sorts, T <: Tuple}
    #
    tup::T
end
# Similiarity includes borrowing ideas and probably code templates.
@eval function (PT::Type{PnmlTuple{sorts,T}})(args::Tuple) where {sorts, T <: Tuple}
    if length(args) != length(sorts::Tuple)
        throw(ArgumentError("Wrong number of arguments to pnml tuple constructor."))
    end
    # Note T(args) might not return something of type T; e.g.
    # Tuple{Type{Float64}}((Float64,)) returns a Tuple{DataType}
    $(Expr(:splatnew, :PT, :(T(args))))
end

function (PT::Type{PnmlTuple{sorts, T}})(pt::PnmlTuple) where {sorts, T <: Tuple}
    if @generated
        Expr(:new, :PT,
             Any[ :(let Tn = fieldtype(PT, $n),
                      ptn = getfield(pt, $(QuoteNode(sorts[n])))
                      ptn isa Tn ? ptn : convert(Tn, ptn)
                  end) for n in 1:eachindex(sorts) ]...)
    else
        PT(map(Fix1(getfield, pt), sorts))
    end
endhouse


function PnmlTuple{sorts}(net::PnmlTuple) where {sorts}
    if @generated
        idx = Int[fieldindex(net, sorts[n]) for n in eachindex(sorts)]
        types = Tuple{(fieldtype(net, idx[n]) for n in eachindex(sorts))...,}
        Expr(:new, :(PnmlTuple{sorts, $types}), Any[ :(getfield(net, $(idx[n]))) for n in eachindex(sorts)]...)
    else
        #length_sorts = length(sorts::Tuple)
        types = Tuple{(fieldtype(typeof(net), sorts[n]) for n in eachindex(sorts))...}
        _new_PnmlTuple(PnmlTuple{sorts, types}, map(Fix1(getfield, net), sorts))
    end
end
