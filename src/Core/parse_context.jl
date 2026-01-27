"""
    fill_nonhl!(net::AbstractPnmlNet) -> Nothing

Fill a DeclDict with built-ins and defaults (that may be redefined).
"""

function fill_nonhl!(net::AbstractPnmlNet)
    builtin_sorts = ((:integer, "Integer", Sorts.IntegerSort()),
                    (:natural, "Natural", Sorts.NaturalSort()),
                    (:positive, "Positive", Sorts.PositiveSort()),
                    (:real, "Real", Sorts.RealSort()),
                    (:bool, "AbstractSortRefBool", Sorts.BoolSort()),
                    (:null, "Null", Sorts.NullSort()),
                    (:dot, "Dot", Sorts.DotSort()), # can be overridden
                    )
    for (tag, name, sort) in builtin_sorts
        #@show typeof(sort)
        #TODO Add list, strings, arbitrarysorts other built-ins.
        nsort = Declarations.NamedSort(tag, name, sort, net)
        fill_sort_tag!(net, tag, nsort)
        #! runtime dispatch detected: `sort` is `Any`
        #! ::NamedSort(%17::Symbol, %18::String, %19::Any, %20::DeclDict)::NamedSort
    end
    return nothing
end


"""
    fill_sort_tag!(net::AbstractPnmlNet, tag::Symbol, sort, dict) -> AbstractSortRef

If not already in the declarations dictionary `dict`, add `sort` with key of `tag`.

Register the tag and create and return an `AbstractSortRef` holding `tag`.
"""
function fill_sort_tag!(net::AbstractPnmlNet, tag::Symbol, sort, dict::Base.Callable)
    ddict = decldict(net)
    idreg = net.idregistry
    if !has_key(ddict, dict, tag) # Do not overwrite existing content. #todo XXX dot XXX
        !isregistered(idreg, tag) && register_id!(idreg, tag)
        dict(ddict)[tag] = sort
    end
    return sortref(dict, tag) # used bu make_sortref
end

function sortref(dict::Base.Callable, tag)
    sortref::SortRef.Type = @match dict begin
        PNML.multisetsorts  => MultisetSortRef(tag)  # sort, basis is a builtin,
        PNML.productsorts   => ProductSortRef(tag)   # sort, tuple of SortRefs
        PNML.partitionsorts => PartitionSortRef(tag) # declaration
        PNML.arbitrarysorts => ArbitrarySortRef(tag) # declaration
        _ => NamedSortRef(tag)
    end
    #@show typeof(sortref)
    return sortref
end


# match sort type to dictionary access method
fill_sort_tag!(net::AbstractPnmlNet, tag, sort::NamedSort) =
    fill_sort_tag!(net, tag, sort, PNML.namedsorts)
fill_sort_tag!(net::AbstractPnmlNet, tag, sort::PartitionSort) =
    fill_sort_tag!(net, tag, sort, PNML.partitionsorts)
fill_sort_tag!(net::AbstractPnmlNet, tag, sort::ArbitrarySort) =
    fill_sort_tag!(net, tag, sort, PNML.arbitrarysorts)

# These two sorts are not used in variable declarations.
# They do not add a name to the contained sorts (or sortrefs).
fill_sort_tag!(net::AbstractPnmlNet, tag, sort::ProductSort) =
    fill_sort_tag!(net, tag, sort, productsorts)
fill_sort_tag!(net::AbstractPnmlNet, tag, sort::MultisetSort) =
    fill_sort_tag!(net, tag, sort, multisetsorts)

"""
    fill_labelp!(net::AbstractPnmlNet) -> Nothing

Fill context with the base built-in label parsers. Useful in test stubs.
"""
fill_labelp!(net::AbstractPnmlNet) = fill_labelp!(net.labelparser)

function fill_labelp!(labelparser::LittleDict{Symbol, Base.Callable})
    labelparser[:initialMarking]   = Parser.parse_initialMarking
    labelparser[:hlinitialMarking] = Parser.parse_hlinitialMarking
    labelparser[:inscription]      = Parser.parse_inscription
    labelparser[:hlinscription]    = Parser.parse_hlinscription
    labelparser[:condition]        = Parser.parse_condition
    labelparser[:graphics]         = Parser.parse_graphics
    labelparser[:name]             = Parser.parse_name
    labelparser[:type]             = Parser.parse_sorttype

    # Extensions to ISO 15909-2:2011, some mentioned in ISO 15909-1:2019, ISO 15909-3:2021.
    labelparser[:fifoinitialMarking] = Parser.parse_fifoinitialMarking
    labelparser[:arctype]  = Parser.parse_arctype
    labelparser[:rate]     = Parser.parse_rate
    labelparser[:priority] = Parser.parse_priority

    return nothing
end
