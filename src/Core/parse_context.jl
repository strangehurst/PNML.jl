"""
    ParseContext

$(DocStringExtensions.TYPEDFIELDS)
"""
@kwdef struct ParseContext
    idregistry::IDRegistry = IDRegistry() # empty
    ddict::DeclDict = DeclDict() # empty
    labelparser::LittleDict{Symbol, Base.Callable} = LittleDict{Symbol, Base.Callable}() # empty
    toolparser::Vector{ToolParser} = ToolParser[] # empty
end

"""
    parse_context() -> ParseContext

 Return a `ParserContext` filled with default values.
 """
function parser_context()
     ctx = fill_nonhl!(ParseContext())
     fill_labelp!(ctx) # Built-in label parsers
end

"""
    fill_nonhl!(ctx::ParseContext) -> DeclDict

Fill a DeclDict with built-ins and defaults (that may be redefined).
"""
function fill_nonhl!(ctx::ParseContext)
    for (tag, name, sort) in ((:integer, "Integer", Sorts.IntegerSort()),
                              (:natural, "Natural", Sorts.NaturalSort()),
                              (:positive, "Positive", Sorts.PositiveSort()),
                              (:real, "Real", Sorts.RealSort()),
                              (:bool, "Bool", Sorts.BoolSort()),
                              (:null, "Null", Sorts.NullSort()),
                              (:dot, "Dot", Sorts.DotSort(ctx.ddict)), #users can override
                              )
        #TODO Add list, strings, arbitrarysorts other built-ins.
        fill_sort_tag!(ctx, tag, Declarations.NamedSort(tag, name, sort, ctx.ddict))
    end
    return ctx
end


"""
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict) -> AbstractSortRef

If not already in the declarations dictionary `dict`, add `sort` with key of `tag`.

`dict` defaults to `namedsorts` a callable returning a dictionary in the DeclDict.

Register the tag and create and return an `AbstractSortRef` holding `tag`.
"""
function fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict::Base.Callable)
    #!println("fill_sort_tag! ", tag)
    # Ensure `sort` is in `dict`, then return SortRef ADT encoding type:
    if !has_key(ctx.ddict, dict, tag) # Do not overwrite existing content.
        !isregistered(ctx.idregistry, tag) && register_id!(ctx.idregistry, tag)
        dict(ctx.ddict)[tag] = sort
    end
    #!@show sort dict
    return @match dict begin
        PNML.multisetsorts  => MultisetSortRef(tag)  # sort, basis is a builtin,
        PNML.productsorts   => ProductSortRef(tag)   # sort, tuple of SortRefs
        PNML.partitionsorts => PartitionSortRef(tag) # declaration
        PNML.arbitrarysorts => ArbitrarySortRef(tag) # declaration
        _ => NamedSortRef(tag)
    end
end

"""
    fill_labelp!(ctx::ParseContext) -> ParseContext

Fill context with the base built-in label parsers. Useful in test stubs.

"""
function fill_labelp!(ctx::ParseContext)
    ctx.labelparser[:initialMarking]   = Parser.parse_initialMarking
    ctx.labelparser[:hlinitialMarking] = Parser.parse_hlinitialMarking
    ctx.labelparser[:fifoinitialMarking] = Parser.parse_fifoinitialMarking
    ctx.labelparser[:inscription]      = Parser.parse_inscription
    ctx.labelparser[:hlinscription]    = Parser.parse_hlinscription
    ctx.labelparser[:condition]        = Parser.parse_condition
    ctx.labelparser[:graphics]         = Parser.parse_graphics
    #ctx.labelparser[:declaration]      = Parser.parse_declaration
    ctx.labelparser[:name]             = Parser.parse_name
    ctx.labelparser[:type]             = Parser.parse_sorttype

    ctx.labelparser[:arctype]  = Parser.parse_arctype
    ctx.labelparser[:rate]     = Parser.parse_rate
    ctx.labelparser[:priority] = Parser.parse_priority
    #ctx.labelparser[:xxx] = Parser.parse_xxx
    return ctx
end
