"""
    fill_enabled_filters!(net::APN) -> Nothing

Fill a dictionary with default enabled filters. Part of the enabling rule.
Based on ISO 15909-1:2019, ISO 15909-3:2021.
"""
function fill_enabled_filters!(net::APN)
    #println("fill_enabled_filters")
    net.enabled_filters[:inhibit] = enable_filter_inhibit
    net.enabled_filters[:reset] = enable_filter_reset
    net.enabled_filters[:read] = enable_filter_read
    net.enabled_filters[:capacity] = enable_filter_capacity
    net.enabled_filters[:priority] =  enable_filter_priority
    net.enabled_filters[:tpn] = enable_filter_tpn
end


"""
    fill_builtin_sorts!(net::APN) -> Nothing

Fill a DeclDict with built-ins and defaults (that may be redefined).
"""
function fill_builtin_sorts!(net::APN)
    __insert_sort!(net, :dot, "Dot", Sorts.DotSort()) # can be overridden
    __insert_sort!(net, :integer, "Integer", Sorts.IntegerSort())
    __insert_sort!(net, :natural, "Natural", Sorts.NaturalSort())
    __insert_sort!(net, :positive, "Positive", Sorts.PositiveSort())
    __insert_sort!(net, :real, "Real", Sorts.RealSort())
    __insert_sort!(net, :bool, "Bool", Sorts.BoolSort())
    __insert_sort!(net, :null, "Null", Sorts.NullSort())

    return nothing
end
function __insert_sort!(net, tag, name, sort::AbstractSort)
    nsort = Declarations.NamedSort(tag, name, sort, net)
    fill_sort_tag!(net, tag, nsort)
    return nothing
end

"""
    fill_sort_tag!(net::APN, tag::Symbol, sort, dict) -> SortRef

If not already in the declarations dictionary `dict`, add `sort` with key of `tag`.

Register the tag and create and return an `SortRef` holding `tag`.
"""
function fill_sort_tag!(net::APN, tag::Symbol, sort, dict::Base.Callable)
    fill_sort_tag!(decldict(net), registry_of(net), tag, sort, dict)
end
function fill_sort_tag!(ddict::DeclDict, idreg, tag::Symbol, sort, dict::Base.Callable)
     # Do not overwrite existing content (except dot).
    if tag === :dot || !haskey(dict(ddict), tag)
        !isregistered(idreg, tag) && register_id!(idreg, tag)
        dict(ddict)[tag] = sort
    end
    return sortref(dict, tag) # used by make_sortref
end

function sortref(dict::Base.Callable, tag)
    #sortref::SortRefImpl.Type =
    @match dict begin
        PNML.multisetsorts  => MultisetSortRef(tag)  # sort, basis is a builtin,
        PNML.productsorts   => ProductSortRef(tag)   # sort, tuple of SortRefs
        PNML.partitionsorts => PartitionSortRef(tag) # declaration
        PNML.arbitrarysorts => ArbitrarySortRef(tag) # declaration
        _ => NamedSortRef(tag)
    end
end


# match sort type to dictionary access method
fill_sort_tag!(net::APN, tag, sort::NamedSort) =
    fill_sort_tag!(net, tag, sort, namedsorts)
fill_sort_tag!(net::APN, tag, sort::PartitionSort) =
    fill_sort_tag!(net, tag, sort, partitionsorts)
fill_sort_tag!(net::APN, tag, sort::ArbitrarySort) =
    fill_sort_tag!(net, tag, sort, arbitrarysorts)

# These two sorts are not used in variable declarations.
# They do not add a name to the contained sorts (or sortrefs).
fill_sort_tag!(net::APN, tag, sort::ProductSort) =
    fill_sort_tag!(net, tag, sort, productsorts)
fill_sort_tag!(net::APN, tag, sort::MultisetSort) =
    fill_sort_tag!(net, tag, sort, multisetsorts)

"""
    fill_builtin_labelparsers!(net::APN) -> Nothing
    fill_builtin_labelparsers!(labelparser::AbstractDict) -> Nothing

Fill context with the base built-in label parsers.
"""
fill_builtin_labelparsers!(net::APN) = fill_builtin_labelparsers!(net.labelparser)

function fill_builtin_labelparsers!(labelparser::AbstractDict)
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

    # __insert_lp!(labelparser, :initialMarking,   Parser.parse_initialMarking)
    # __insert_lp!(labelparser, :hlinitialMarking, Parser.parse_hlinitialMarking)
    # __insert_lp!(labelparser, :inscription,      Parser.parse_inscription)
    # __insert_lp!(labelparser, :hlinscription,    Parser.parse_hlinscription)
    # __insert_lp!(labelparser, :condition,        Parser.parse_condition)
    # __insert_lp!(labelparser, :graphics,         Parser.parse_graphics)
    # __insert_lp!(labelparser, :name,             Parser.parse_name)
    # __insert_lp!(labelparser, :type,             Parser.parse_sorttype)

    # # Extensions to ISO 15909-2:2011, some mentioned in ISO 15909-1:2019, ISO 15909-3:2021.
    # __insert_lp!(labelparser, :fifoinitialMarking, Parser.parse_fifoinitialMarking)
    # __insert_lp!(labelparser, :arctype,  Parser.parse_arctype)
    # __insert_lp!(labelparser, :rate,     Parser.parse_rate)
    # __insert_lp!(labelparser, :priority, Parser.parse_priority)
   return nothing
end
function __insert_lp!(labelparser, tag, parser)
    labelparser[tag] = parser
    return nothing
end


"""
    fill_builtin_toolparsers!(net::APN) -> Nothing
    fill_builtin_toolparsers!(toolparsers::AbstractDict) -> Nothing

Fill context with the base built-in tool parsers.
"""
fill_builtin_toolparsers!(net::APN) = fill_builtin_toolparsers!(net.toolparser)

function fill_builtin_toolparsers!(toolparsers::AbstractDict)
    for toolparser in (
            ToolParser("org.pnml.tool", "1.0", Parser.tokengraphics_content),
            ToolParser("nupn", "1.1", Parser.nupn_content),
        )
        #@show toolparser
        fill_toolparsers!(toolparsers, toolparser)
    end
    return nothing
end

"Add parser to dictionary"
function fill_toolparsers!(toolparsers::AbstractDict, tparser)
    if haskey(toolparsers, name(tparser)=>version(tparser))
        @warn "ignoring repeated toolparser" name(tparser)=>version(tparser) tparser
    else
        toolparsers[name(tparser)=>version(tparser)] = func(tparser)
    end
    return toolparsers
end
