"""
    ParseContext

$(DocStringExtensions.TYPEDFIELDS)
"""
@kwdef struct ParseContext
    idregistry::PnmlIDRegistry = PnmlIDRegistry() # empty
    ddict::DeclDict = DeclDict() # empty
    labelparser::Vector{LabelParser} = LabelParser[] # empty
    toolparser::Vector{ToolParser} = ToolParser[] # empty
end

"""
    parse_context() -> ParseContext

 Return a `ParserContext` filled with default values.
 """
function parser_context()
     fill_nonhl!(ParseContext())
end

"""
    fill_nonhl!(ctx::ParseContext; idreg::PnmlIDRegistry) -> DeclDict

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
        usersorts(ctx.ddict)[tag] = UserSort(tag, ctx.ddict) # fill_nonhl!
    end
    return ctx
end


"""
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort) -> fill_sort_tag!(ctx, tag, sort, dict)
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict) -> AbstractSortRef

If not already in the declarations dictionary `dict`, add `sort` with key of `tag`.

`dict` defaults to `namedsorts` a callable returning a dictionary in the DeclDict.

Register the tag and create and return an `AbstractSortRef` holding `tag`.
"""
function fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict::Base.Callable)
    # if dict == PNML.namedsorts && isa(sort, NamedSort)
    #     @error "dict == PNML.namedsorts && isa(sort, NamedSort)" tag dict sort
    # end

    if !has_key(ctx.ddict, dict, tag) # Do not overwrite existing content.
        !isregistered(ctx.idregistry, tag) && register_id!(ctx.idregistry, tag)
        dict(ctx.ddict)[tag] = sort
    end

    # Will ensure `sort` is in `dict`, then do this:
    return @match dict begin  #! return a concrete SortRef.Type
        PNML.multisetsorts  => MultisetSortRef(tag)  # sort, basis is a builtin, in a namedsort
        PNML.productsorts   => ProductSortRef(tag)   # sort, tuple of usersort, in a namedsort
        PNML.partitionsorts => PartitionSortRef(tag) # declaration
        PNML.arbitrarysorts => ArbitrarySortRef(tag) # declaration
        _ => NamedSortRef(tag)                       # declaration
        # usersort -> namedsort | partitionsort | arbitrary sort
    end
    #! DO NOT create a UserSort here.
end
