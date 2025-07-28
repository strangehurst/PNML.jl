#

"Fill and return a `ParserContext` object."
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
        #! XXX fill a usersort slot? Add dicts for SortRefs?
    end
    return ctx
end


# NamedSort(tag, name, sort, ctx.ddict)
# PartitionSort(tag, name, SortRef, Vector{PartitionElement}, ctx.ddict)
# ArbitrarySort(tag, name, symbol, ctx.ddict)
# ProductSort(SortRef..., , ctx.ddict)
# MultsetSort(SortRef, ctx.ddict)

"""
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort) -> fill_sort_tag!(ctx, tag, sort, dict)
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict) -> SortRef

If not already in the declarations dictionary `dict`, add `sort` with key of `tag`.

`dict` defaults to `namedsorts` a callable returning a dictionary in the DeclDict.

Register the tag and create and return a `SortRef` holding `tag`.
"""
function fill_sort_tag!(ctx::ParseContext, tag::Symbol, sort, dict::Base.Callable)
    # if dict == PNML.namedsorts && isa(sort, NamedSort)
    #     @error "dict == PNML.namedsorts && isa(sort, NamedSort)" tag dict sort
    # end

    if !has_key(ctx.ddict, dict, tag) # Do not overwrite existing content.
        #println("fill_sort_tag!($(repr(tag)), $(typeof(sort)) in $(dict)") #! debug
        !isregistered(ctx.idregistry, tag) && register_id!(ctx.idregistry, tag)
        dict(ctx.ddict)[tag] = sort
    end

    #! 2021-07-21 refactor fill_sort_tag!() to place sorts into dicts, separate namedsorts
    #! into singleton, enumerations, and all with non-singular types.

    # Will ensure `sort` is in `dict`, then do this:
    return @match dict begin     #! return a SortRef
        PNML.multisetsorts  => MultisetSortRef(tag)  # sort, basis is a builtin, in a namedsort
        PNML.productsorts   => ProductSortRef(tag)   # sort, tuple of usersort, in a namedsort
        PNML.partitionsorts => PartitionSortRef(tag) # declaration
        PNML.arbitrarysorts => ArbitrarySortRef(tag) # declaration
        _ => NamedSortRef(tag)                       # declaration
        # usersort -> namedsort | partitionsort | arbitrary sort
    end
    #! DO NOT create a UserSort here. Where?
end
