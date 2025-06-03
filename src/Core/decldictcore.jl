"""
    struct DeclDict

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Each keyed by REFID symbols.
"""
@kwdef struct DeclDict
    """
        Holds [`VariableDeclaration`](@ref).
        A [`Variable`](@ref) is used to locate the declaration's name and sort.
    """
    variabledecls::Dict{Symbol, Any} = Dict{Symbol, Any}()

    namedsorts::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitrarysorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    partitionsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # OperatorDecls
    # namedoperators are used to access built-in operators
    namedoperators::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitraryoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol, Any}       = Dict{Symbol, Any}()
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, Any}        = Dict{Symbol, Any}()

    # Use an REFID symbol as a network-level "global" to reference
    # SortDeclaration or Operatordeclaration.
    # usersort used to wrap REFID to <: SortDeclaration is well used
    usersorts::Dict{Symbol, Any}     = Dict{Symbol, Any}() #
    useroperators::Dict{Symbol, Any} = Dict{Symbol, Any}() # Advanced users define ops?
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts, :useroperators)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

"Return dictonary of UserSort"
usersorts(dd::DeclDict)      = dd.usersorts
"Return dictonary of UserOperator"
useroperators(dd::DeclDict)  = dd.useroperators
"Return dictonary of VariableDecl"
variabledecls(dd::DeclDict)  = dd.variabledecls
"Return dictonary of NamedSort"
namedsorts(dd::DeclDict)     = dd.namedsorts
"Return dictonary of ArbitrarySort"
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
"Return dictonary of PartitionSort"
partitionsorts(dd::DeclDict) = dd.partitionsorts
"Return dictonary of NamedOperator"
namedoperators(dd::DeclDict) = dd.namedoperators
"Return dictonary of ArbitraryOperator"
arbitraryops(dd::DeclDict)   = dd.arbitraryoperators
"Return dictonary of partitionops (PartitionElement)"
partitionops(dd::DeclDict)   = dd.partitionops
"Return dictonary of FEConstant"
feconstants(dd::DeclDict)    = dd.feconstants

"""
    declarations(dd::DeclDict) -> Iterator

Return an iterator over all the declaration dictionaries' values.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),
        values(usersorts(dd)),
        values(useroperators(dd)),
    ])
end

has_variabledecl(dd::DeclDict, id::Symbol)   = haskey(variabledecls(dd), id)
has_namedsort(dd::DeclDict, id::Symbol)      = haskey(namedsorts(dd), id)
has_arbitrarysort(dd::DeclDict, id::Symbol)  = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_namedop(dd::DeclDict, id::Symbol)        = haskey(namedoperators(dd), id)
has_arbitraryop(dd::DeclDict, id::Symbol)    = haskey(arbitraryops(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)
has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)
has_useroperator(dd::DeclDict, id::Symbol)   = haskey(usersorts(dd), id)

"Lookup variable with `id` in DeclDict."
variable(dd::DeclDict, id::Symbol)       = variabledecls(dd)[id]
"Lookup namedsort with `id` in DeclDict."
namedsort(dd::DeclDict, id::Symbol)      = namedsorts(dd)[id]
"Lookup arbitrarysort with `id` in DeclDict."
arbitrarysort(dd::DeclDict, id::Symbol)  = arbitrarysorts(dd)[id]
"Lookup partitionsort with `id` in DeclDict."
partitionsort(dd::DeclDict, id::Symbol)  = partitionsorts(dd)[id]
"Lookup namedop with `id` in DeclDict."
namedop(dd::DeclDict, id::Symbol)        = namedoperators(dd)[id]
"Lookup arbitraryop with `id` in DeclDict."
arbitraryop(dd::DeclDict, id::Symbol)    = arbitraryoperators(dd)[id]
"Lookup partitionop with `id` in DeclDict."
partitionop(dd::DeclDict, id::Symbol)    = partitionops(dd)[id]
"Lookup feconstant with `id` in DeclDict."
feconstant(dd::DeclDict, id::Symbol)     = feconstants(dd)[id]
"Lookup usersort with `id` in DeclDict."
usersort(dd::DeclDict, id::Symbol)       = usersorts(dd)[id]
"Lookup useroperator with `id` in DeclDict."
useroperator(dd::DeclDict, id::Symbol)   = useroperators(dd)[id]

#TODO :useroperator -> opdictionary -> op  # how type-stable is this?
"Return tuple of operator dictionary fields in the Declaration Dictionaries."
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
"Return iterator over operator dictionaries of Declaration Dictionaries."
_ops(dd) = Iterators.map(Fix1(getfield, dd), _op_dictionaries())

"Return tuple of sort dictionary fields in the Declaration Dictionaries."
_sort_dictionaries() = (:namedsorts, :usersorts, :partitionsorts, :arbitrarysorts)
"Return iterator over sort dictionaries of Declaration Dictionaries."
_sorts(dd) = Iterators.map(Fix1(getfield, dd), _sort_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(keys, _ops(dd)))

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

#! Change first to only when de-duplication implementd? as test?
"Return operator dictionary containing key `id`."
_get_op_dict(dd::DeclDict, id::Symbol) = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))

"""
    operator(dd::DeclDict, id::Symbol) -> AbstractOperator

Return operator TermInterface expression for `id`.
    `toexpr(::OpExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

"Operator Declarations" include: :namedoperator, :feconstant, :partitionelement, :arbitraryoperator
with types `NamedOperator`, `FEConstant`, `PartitionElement`, `ArbitraryOperator`.
These define operators of different types that are placed into separate dictionaries.

#! CORRECT AbstractOperator type hierarchy that has `Operator` as concrete type.
#! AbstractDeclarations and AbstractTerms are "parallel" hierarchies in the UML,
#! with AbstractTerms divided into AbstractOperators and AbstractVariables.

useroperator(REFID) is used to locate the operator definition, when it is found in `feconstants()`,
is a callable returning a `FEConstant` literal.

    `toexpr(::FEConstantEx, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

The FEConstant operators defined by the declaration do not have a distinct type name in the specification.
Note that a FEConstant's value in the specification is its identity.
We could use `objectid(::FEConstant)`, `REFID` or `name` for output value.
Output sort of op is FEConstant.

Other `OperatorDeclaration` dictionarys also hold `TermInterface` expressions accessed by

    `toexpr(::PnmlExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

where `PnmlExpr` is the `TermInterface` to match `OperatorDeclaration`.
With output sort to match `OperatorDeclaration` .

#TODO named operator input variables and thier sorts

#TODO partition element

#TODO arbitrary opearator

#TODO built-in operators
"""
function operator(dd::DeclDict, opid::Symbol)
    #println("operator($id)")
    for dict in _ops(dd)
        if haskey(dict, opid)
            #@show dict[opid]
            return dict[opid] #! not type stable because each dict holds different type.
        end
    end
    return nothing
end

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    # println("validate declarations")
    # show_sorts(dd)
    # @show _op_dictionaries()
    # println()
    # @show all(Fix1(hasfield, typeof(dd)), _op_dictionaries())
    # foreach(_op_dictionaries()) do opd
    #     println("opd = ", opd, ", length = ", length(getfield(dd, opd)))
    #     foreach(println, getfield(dd, opd))
    # end
    # #@show collect(_ops(dd))
    # println()
    # @show collect(operators(dd))
    # println()
    # for opid in operators(dd)
    #     @show operator(opid)
    #     @show operator(opid)(NamedTuple()) # operators take parameters
    # end
    # println("-----------------------------------------")
    return true
end

function show_sorts(dd::DeclDict)
    # println("show_sorts")
    @show _sort_dictionaries()
#     foreach(_sort_dictionaries()) do s
#         println("sort = ", s, ", length = ", length(getfield(dd, s)))
#         foreach(println, getfield(dd, s))
#     end
#     println()
end


@kwdef struct ParseContext
    idregistry::PnmlIDRegistry
    ddict::DeclDict
    labelparser::Vector{LabelParser} = LabelParser[]
    toolparser::Vector{ToolParser} = ToolParser[]
end

function parser_context()
    dd = DeclDict() # empty
    idreg = PnmlIDRegistry()
    fill_nonhl!(ParseContext(; idregistry=idreg, ddict=dd))# Fill and return.
end


"""
    fill_nonhl!(ctx::ParseContext; idreg::PnmlIDRegistry) -> DeclDict

Fill a DeclDict with defaults and values needed by non-high-level networks.

    NamedSort(:integer, "Integer", IntegerSort())
    NamedSort(:natural, "Natural", NaturalSort())
    NamedSort(:positive, "Positive", PositiveSort())
    NamedSort(:real, "Real", RealSort())
    NamedSort(:dot, "Dot", DotSort())
    NamedSort(:bool, "Bool", BoolSort())

    UserSort(:integer, ddict)
    UserSort(:natural, ddict))
    UserSort(:positive, ddict))
    UserSort(:real, ddict))
    UserSort(:dot, ddict))
    UserSort(:bool, ddict))
"""
function fill_nonhl!(ctx::ParseContext)
    for (tag, name, sort) in ((:integer, "Integer", Sorts.IntegerSort()),
                              (:natural, "Natural", Sorts.NaturalSort()),
                              (:positive, "Positive", Sorts.PositiveSort()),
                              (:real, "Real", Sorts.RealSort()),
                              (:dot, "Dot", Sorts.DotSort(ctx.ddict)), #users can override
                              (:bool, "Bool", Sorts.BoolSort()),
                              (:null, "Null", Sorts.NullSort()),
                              )
        #TODO Add list, strings, arbitrarysorts other built-ins.
        fill_sort_tag!(ctx, tag, name, sort)
    end
    return ctx
end

"""
    fill_sort_tag!(ctx::ParseContext, tag::Symbol, name, sort)

If not already in the declarations dictionary, create and add a namedsort, usersort duo for `tag`.
"""
function fill_sort_tag!(ctx::ParseContext, tag::Symbol, name, sort)
    if !has_namedsort(ctx.ddict, tag) # Do not overwrite existing content.
        !isregistered(ctx.idregistry, tag) && register_id!(ctx.idregistry, tag)
        namedsorts(ctx.ddict)[tag] = NamedSort(tag, name, sort, ctx.ddict)
    end

    if !has_usersort(ctx.ddict, tag) # Do not overwrite existing content.
        # DO NOT register REFID! ID owned by NamedSort.
        usersorts(ctx.ddict)[tag] = UserSort(tag, ctx.ddict)
    end
end
