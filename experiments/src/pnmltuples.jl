"""
    PnmlTuple

PnmlTuples have a similarity to NamedTuples with Sorts taking the place of names.
Will not achieve the same transparancy and efficency as NamedTuples.
NB: NamedTuples uses Symbols where PnmlTuple uses Sorts (must be made bitstype
"""
struct PnmlTuple{sorts, T} where {sorts, T <: Tuple}
    #
    tup::T
end

# if nameof(@__MODULE__) === :Base


# PnmlTuple(tuple(AbstractSort), tuple(AbstractTerm)
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
                  end) for n in 1:length(sorts) ]...)
    else
        PT(map(Fix1(getfield, pt), sorts))
    end
endhouse


function PnmlTuple{sorts}(nt::PnmlTuple) where {sorts}
    if @generated
        idx = Int[ fieldindex(nt, sorts[n]) for n in 1:length(sorts) ]
        types = Tuple{(fieldtype(nt, idx[n]) for n in 1:length(idx))...}
        Expr(:new, :(PnmlTuple{sorts, $types}), Any[ :(getfield(nt, $(idx[n]))) for n in 1:length(idx) ]...)
    else
        length_sorts = length(sorts::Tuple)
        types = Tuple{(fieldtype(typeof(nt), sorts[n]) for n in 1:length_sorts)...}
        _new_PnmlTuple(PnmlTuple{sorts, types}, map(Fix1(getfield, nt), sorts))
    end
end
