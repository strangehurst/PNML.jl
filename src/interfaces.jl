# Declare&Document interface functions of PNML.jl
# Any method defined in this file should operate on `Any`.

"""
    pid(x) -> Symbol

Return pnml id symbol.
"""
function pid end

"""
    tag(x) -> Symbol

Return tag symbol.
"""
function tag end

"""
    name(x) -> String

Return name String. Default to empty string.
"""
function name end

"""
    has_xml(x) -> Bool

Return `true` if has XML attached. Defaults to `false`.
"""
function has_xml end
has_xml(x::Any) = hasproperty(x, :xml)

"""
    xmlnode(x) -> XMLNode

Return attached xml node.
"""
function xmlnode end


"""
    has_labels(x) -> Bool

Does x have any labels.
""" 
function has_labels end

"""
    has_label(x, tag::Symbol) -> Bool

Does any label have a matching `tagvalue`.
""" 
function has_label end

"""
    get_label(x, tag::Symbol) -> PnmlLabel

Return first label with a matching `tagvalue`.
"""
function get_label end


#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return the [`PnmlType`](@ref) subtype representing the flavor (or pntd) of this kind of 
Petri Net Graph.

See also [`pnmltype`](@ref)
"""
function nettype end

"""
$(TYPEDSIGNATURES)

Return vector of pages.
"""
function pages end

"""
$(TYPEDSIGNATURES)

Return vector of places.
"""
function places end

"""
$(TYPEDSIGNATURES)

Return vector of place IDs.
"""
function place_ids end

"""
$(TYPEDSIGNATURES)
Return vector of transitions.
"""
function transitions end

"""
$(TYPEDSIGNATURES)

Return vector of arcs.
"""
function arcs end

"""
$(TYPEDSIGNATURES)
Return vector of reference places.
"""
function refplaces end

"""
$(TYPEDSIGNATURES)

Return vector of reference transitions.
"""
function reftransitions end
"""
$(TYPEDSIGNATURES)

Return `true` if any `arc` has `id`.
"""
function has_arc end

"""
$(TYPEDSIGNATURES)
Return arc with `id` if found, otherwise `nothing`.
"""
function arc end

"""
$(TYPEDSIGNATURES)

Return vector of arc ids.
"""
function arc_ids end

"""
$(TYPEDSIGNATURES)
Return vector of arcs that have a source or target of transition `id`.

See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function all_arcs end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source of transition `id`.

See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function src_arcs end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a target of transition `id`.

See also [`all_arcs`](@ref), [`src_arcs`](@ref).
"""
function tgt_arcs end

"""
$(TYPEDSIGNATURES)
Return incription value of `arc`.
"""
function inscription end

"""
$(TYPEDSIGNATURES)
"""
function has_refP end

"""
$(TYPEDSIGNATURES)
"""
function has_refT end

"""
$(TYPEDSIGNATURES)
"""
function refplace_ids end

"""
$(TYPEDSIGNATURES)
"""
function reftransition_ids end

"""
Return reference place matching `id`.
$(TYPEDSIGNATURES)
"""
function refplace end

"""
Return reference transition matching `id`.
$(TYPEDSIGNATURES)
"""
function reftransition end

"""
$(TYPEDSIGNATURES)

Is there any place with `id`?
"""
function has_place end

"""
$(TYPEDSIGNATURES)

Return the place with `id`.
"""
function place end

"""
$(TYPEDSIGNATURES)

Return vector of place ids.
"""

"""
$(TYPEDSIGNATURES)

Return marking value of a place `p`.
"""
function marking end

"""
$(TYPEDSIGNATURES)

Return a labelled vector with key of place id and value of marking.
"""
function initialMarking end

"""
$(TYPEDSIGNATURES)

Is there a transition with `id`?
"""
function has_transition end

"""
$(TYPEDSIGNATURES)
"""
function transition end

"""
$(TYPEDSIGNATURES)
"""
function transition_ids end

"""
$(TYPEDSIGNATURES)

Return a labelled vector of condition values for net `s`. Key is transition id.
"""
function conditions end

"""
$(TYPEDSIGNATURES)

Return condition value of `transition`.
"""
function condition end

