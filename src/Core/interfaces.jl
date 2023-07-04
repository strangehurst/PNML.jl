# Declare & Document interface functions of PNML.jl
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
    has_name(x) -> Bool

Return true if there is a name.
"""
function has_name end

"""
    name(x) -> String

Return name String. Default to empty string.
"""
function name end

#--------------------------------
# XML
#--------------------------------
"""
    has_xml(x) -> Bool

Return `true` if `x` has XML attached. Defaults to `false`.
"""
function has_xml end
has_xml(x::Any) = hasproperty(x, :xml)

"""
    xmlnode(x) -> XMLNode

Return attached xml node.
"""
function xmlnode end

#-------------------------------------------------------
# LABELS  #! note that they are similar to TOOLINFO which should be documented hereabouts in interfaces
#-------------------------------------------------------

"""
    has_labels(x) -> Bool

Does x have any labels.
"""
function has_labels end

"""
    labels(x) -> Iterateable

Return iterator of labels attached to `x`.
"""
function labels(x) end

"""
    has_label(x, tag::Symbol) -> Bool

Does `x` have any label have a matching `tagvalue`.
"""
function has_label end

"""
    get_label(x, tag::Symbol) -> PnmlLabel

Return first label of `x` with a matching `tagvalue`.
"""
function get_label end


#--------------------------------------------
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

Return vector of all pages.
"""
function pages end

#--------------------------------------------
# PLACES & MARKINGS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return vector of all places.
"""
function places end

"""
$(TYPEDSIGNATURES)

Return vector of all place IDs.
"""
function place_idset end

"""
$(TYPEDSIGNATURES)

Return `true` if there is any place with `id`?
"""
function has_place end

"""
$(TYPEDSIGNATURES)

Return the place with `id`.
"""
function place end

"""
$(TYPEDSIGNATURES)

Return marking value of a place.
"""
function marking end

#! CHANGE NAME
"""
$(TYPEDSIGNATURES)

Return a labelled vector with key of place id and value of its marking.
Marking value is evaluated to be a number (Int or Float64). High-level nets
evaluate a `Term` of the many-sorted algebra to an `Int`.
"""
function initialMarking end

#--------------------------------------------
# TRANSITIONS & CONDITIONS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return vector of all transitions.
"""
function transitions end

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
function transition_idset end

"""
$(TYPEDSIGNATURES)

Return a labelled vector of condition values.
"""
function conditions end

"""
$(TYPEDSIGNATURES)

Return condition value of `transition`.
"""
function condition end

#--------------------------------------------
# ARCS & INSCRIPTIONS
#--------------------------------------------
"""
    arcs(p::Page) -> iterator
    arcs(n::PnmlNet) -> iterator
    arcs(p::AbstractPetriNet) -> iterator

Return iterator over arc ids.
"""
function arcs end
"""
$(TYPEDSIGNATURES)+

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

Return set arc ids.
"""
function arc_idset end

"""
$(TYPEDSIGNATURES)
Return arcs that have a source or target of transition `id`.

See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function all_arcs end

"""
$(TYPEDSIGNATURES)

Return arcs that have a source of transition `id`.

See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function src_arcs end

"""
$(TYPEDSIGNATURES)

Return arcs that have a target of transition `id`.

See also [`all_arcs`](@ref), [`src_arcs`](@ref).
"""
function tgt_arcs end

"""
$(TYPEDSIGNATURES)
Return incription value of `arc`.
"""
function inscription end

#--------------------------------------------
# REFERENCES
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return vector of all reference places.
"""
function refplaces end

"""
$(TYPEDSIGNATURES)

Return vector of all reference transitions.
"""
function reftransitions end

"""
$(TYPEDSIGNATURES)
"""
function has_refP end

"""
$(TYPEDSIGNATURES)
"""
function has_refT end

"""
    refplace_idset(x) -> Set{Symbol} #TODO iterator?

Return reference place pnml ids.
"""
function refplace_idset end

"""
    reftransition_idset(x) -> Set{Symbol} #TODO iterator?

Return reference transition pnml ids.
"""
function reftransition_idset end

"""
$(TYPEDSIGNATURES)
Return reference place matching `id`.
"""
function refplace end

"""
$(TYPEDSIGNATURES)
Return reference transition matching `id`.
"""
function reftransition end

#--------------------------------------------
#
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
"""
function pnmlnet_type end

"""
$(TYPEDSIGNATURES)
Type of Page.
"""
function page_type end

"""
$(TYPEDSIGNATURES)
Type of Place.
"""
function place_type end

"""
$(TYPEDSIGNATURES)
Type of TYransition.
"""
function transition_type end

"""
$(TYPEDSIGNATURES)
Type of Arc.
"""
function arc_type end

"""
$(TYPEDSIGNATURES)
Tyoe of RefPlace.
"""
function refplace_type end

"""
$(TYPEDSIGNATURES)
Type of RefTransition.
"""
function reftransition_type end

"""
$(TYPEDSIGNATURES)
Type of `Condition{condition_value_type(T)}`
"""
function condition_type end
"""
$(TYPEDSIGNATURES)
Return value type.
"""
function condition_value_type end

"""
$(TYPEDSIGNATURES)
Type of Inscription{inscription_value_type(T)}.
"""
function inscription_type end

"""
$(TYPEDSIGNATURES)
Return value type.
"""
function inscription_value_type end

"""
$(TYPEDSIGNATURES)
Return type of Marking{marking_value_type(T)}.
"""
function marking_type end

"""
$(TYPEDSIGNATURES)
Return value type.
"""
function marking_value_type end

"""
$(TYPEDSIGNATURES)
Return type of sort.
"""
function sort_type end

"""
$(TYPEDSIGNATURES)
Return value type.
"""
function term_value_type end

"""
$(TYPEDSIGNATURES)
Return `Coordinate{coordinate_value_type(T)}`
"""
function coordinate_type end
"""
$(TYPEDSIGNATURES)
Return type of value in a `Coordinate`.
"""
function coordinate_value_type end
