#--------------------------------
# Kinds of Petri Nets
"""
$(TYPEDEF)

Abstract root of a dispatch type based on Petri Net Type Definition (pntd).

Each Petri Net Markup Language (PNML) network element will have a single pntd URI
as a required type XML attribute. That URI could/should refer to a RelaxNG schema defining
the syntax and semantics of the XML model.

See (`pnmltype_map)[@ref] for the map from type string to a  dispatch singleton.

Within PNML.jl no schema-level validation is done. Nor is any use made of
the schema within the code. Schemas, UML, ISO Specification and papers used
to inform the design. See https://www.pnml.org/ for details.

In is allowed by the PNML specification to omit validation with the presumption that
some specialized, external tool can be applied, thus allowing the file format to be
used for inter-tool communication with lower overhead.

Some pnml files exist that do not use a valid type URI.
However it is done, an appropriate subtype of `PnmlType` must be chosen.
Refer to [`to_net_type`](@ref) and [`pnmltype_map`](@ref) for how to get
from the URI string to a Julia type.
"""
abstract type PnmlType end

"""
Most minimal Petri Net type that is the foundation of all pntd.
"""
abstract type AbstractPnmlCore  <: PnmlType end
"""
Base of High Level Petri Net pntds.
"""
abstract type AbstractHLCore    <: AbstractPnmlCore end


"All Petri Nets support core."
struct PnmlCore      <: AbstractPnmlCore end
"Place-Transition Petri Nets add small extensions to core."
struct PTNet         <: AbstractPnmlCore end

"High-Level Petri Nets add large extensions to core."
struct HLCore        <: AbstractHLCore end
struct PT_HLPNG      <: AbstractHLCore end
struct SymmetricNet  <: AbstractHLCore end
struct StochasticNet <: AbstractHLCore end
struct TimedNet      <: AbstractHLCore end
struct OpenNet       <: AbstractHLCore end
struct HLNet         <: AbstractHLCore end

"""
    default_pntd_map

Map from Petri Net Type Definition (pntd) URI to Symbol.
The URI used can be any string regardless of any violation of the PNML Specification.
There is a companion map [`pnmltype_map`](@ref) that takes the symbol to a type object.
The 'pntd symbol' should match the name used in the URI with inconvinient characters
removed or replaced. For example, '-' is replaced by '_'.
"""
const default_pntd_map = Dict{AbstractString,Symbol}(
    "http://www.pnml.org/version-2009/grammar/ptnet" => :ptnet,
    "http://www.pnml.org/version-2009/grammar/highlevelnet" => :hlnet,
    "http://www.pnml.org/version-2009/grammar/pnmlcoremodel" => :pnmlcore,
    "http://www.pnml.org/version-2009/grammar/pnmlcore" => :pnmlcore,
    "http://www.pnml.org/version-2009/grammar/pt-hlpng" => :pt_hlpng,
    "http://www.pnml.org/version-2009/grammar/symmetricnet" => :symmetric,
    "pnmlcore"   => :pnmlcore,
    "ptnet"      => :ptnet,
    "hlcore"     => :hlcore,
    "pt-hlpng"   => :pt_hlpng,
    "pt_hlpng"   => :pt_hlpng,
    "symmetric"  => :symmetric,
    "symmetricnet" => :symmetric,
    "stochastic"   => :stochastic,
    "timed"        => :timednet,
    "nonstandard"  => :pnmlcore,
    "open"         => :pnmlcore
    )

# TODO: wrap dict in a struct. use __init__?

"""
    pnmltype_map

The keys are the supported kinds of Petri Nets.

Provides a place to abstract relationship of pntd name and implementation type.
Allows multiple strings to map to the same parser implementation.
Is a point at which different parser implmentations may be introduced.
"""
const pnmltype_map = Dict{Symbol, PnmlType}(
    :pnmlcore   => PnmlCore(),
    :hlcore     => HLCore(),
    :ptnet      => PTNet(),
    :hlnet      => HLNet(),
    :pt_hlpng   => PT_HLPNG(),
    :symmetric  => SymmetricNet(),
    :stochastic => StochasticNet(),
    :timednet   => TimedNet(),
    )

"Add or replace mapping from symbol `s` to nettype dispatch singleton `t`."
add_nettype!(d::AbstractDict, s::Symbol, t::T) where {T<:PnmlType} = d[s] = t

"""
    to_net_type(uri)
    to_net_type(symbol)

Map either a text string or a symbol to a dispatch type singlton.

While that string may be a URI for a pntd, we treat it as a simple string without parsing.
The pnmltype_map and pntd_map are both assumed to be correct here.

Unknown or empty `uri` will map to symbol `:pnmlcore` as part of the logic.
Unknown `symbol` returns `nothing`.
"""
function to_net_type end
to_net_type(uri::AbstractString; kw...) = to_net_type(to_net_type_sym(uri); kw...)

function to_net_type(s::Symbol; pnmltype_map=pnmltype_map)
    if haskey(pnmltype_map, s)
        return pnmltype_map[s]
    else
        @debug "Unknown PNTD symbol $s"
        return nothing
    end
end
to_net_type(t::T) where {T<:PnmlType} = t
"""
    to_net_type_sym(uri)
We map `uri` to a symbol using a dictionary like [`default_pntd_map`](@ref).
Return symbol that is a valid pnmltype_map key. Defaults to `:pnmlcore`.
"""
function to_net_type_sym(uri::AbstractString; pntd_map=default_pntd_map)
    if isempty(uri)
        @debug "Empty PNML type URI will be mapped to :pnmlcore model."
    elseif !haskey(pntd_map, uri)
        @debug "Unknown PNML type URI $uri will be mapped to :pnmlcore model."
    else
        return pntd_map[uri]
    end
    return :pnmlcore
end

"Log a warning if `s` is not a known Petri Net Markup Language schema/pntd. "
function validate(s::Symbol; pnmltype_map=pnmltype_map)
    s ∉ keys(pnmltype_map) && @debug "'$(s)' is not a known pntd type symbol."
    return s
end
