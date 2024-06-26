# Declare & Document interface functions of PNML.jl
# Any method defined in this file should operate on `Any`.

"""
    pid(x) -> Symbol

Return pnml id symbol. An id's value is identity/unique. A tag may have multiple of same value.
"""
function pid end

"""
    tag(x) -> Symbol

Return tag symbol. A tag may have multiple of same value. An id's value is identity/unique.
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

#-------------------------------------------------------
# LABELS
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
function labels end

"""
    has_label(x, tag::Symbol) -> Bool

Does `x` have any label with a matching `tag`.
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
    pages(net::PnmlLabel|page::Page) -> iterator

Return iterator of pages directly owned by that object.

See [`allpages`](@ref) for an iterator over all pages in the PNML network model.
When there is only one `page` in the `net`, or all pages are owned by the 'net' itself,
'allpages' and 'pages` behave the same.

Maintains order (insertion order).
"""
function pages end

#--------------------------------------------
# PLACES & MARKINGS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return iterator of all places.
"""
function places end

"""
$(TYPEDSIGNATURES)

Return iterator of all place IDs.
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

Return the initial marking of a place.
"""
function initial_marking end

#--------------------------------------------
# TRANSITIONS & CONDITIONS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return iterator of all transitions.
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

Return condition's value of `transition`.
"""
function condition end

#--------------------------------------------
# ARCS & INSCRIPTIONS
#--------------------------------------------
"""
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

Return iterator over arc ids.
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
function has_refplace end

"""
$(TYPEDSIGNATURES)
"""
function has_reftransition end

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
Type of `Condition`.
"""
function condition_type end

"""
    value(x)
Return value of x. Can be a wrapped value or a derived value.
"""
function value end

"""
$(TYPEDSIGNATURES)
Return value type.
"""
function condition_value_type end

"""
    inscription_type(pntd) -> Inscription{inscription_value_type(pntd)}.
"""
function inscription_type end

"""
    inscription_value_type(pntd) -> Union{Int64, Float64, PnmlMultiset{<:Any, <:AbstractSort}}
Return value type.
"""
function inscription_value_type end

"""
    marking_type(pntd) -> Marking{marking_value_type(pntd)}.
"""
function marking_type end

"""
$(TYPEDSIGNATURES)
Return value type.
"""
function marking_value_type end

# """
# $(TYPEDSIGNATURES)
# Return value type.
# """
# function term_value_type end

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

#---------------------------------------------------------------------------
# Extend by allowing a transition to be labeled with a floating point rate.
#---------------------------------------------------------------------------
"""
    rate_value_type(::PnmlType) -> Number

Return rate value type based on net type.
"""
function rate_value_type end
