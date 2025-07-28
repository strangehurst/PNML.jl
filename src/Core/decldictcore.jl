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

    # Built-in sorts live in named sorts. A sort declaration.
    namedsorts::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitrarysorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    partitionsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    multisetsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    productsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # OperatorDecls
    # namedoperators are also used to access built-in operators.
    namedoperators::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitraryoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol, Any}       = Dict{Symbol, Any}()
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, Any}        = Dict{Symbol, Any}()

    # Use an REFID symbol as a network-level "global" to reference
    # SortDeclaration or Operatordeclaration.

    # usersort used to wrap REFID to <: SortDeclaration is well used
    #! 2025-07-14 moving to SortRef to wrap a REFID and retain type information.
    #! UserSorts will appear in the input XML
    usersorts::Dict{Symbol, Any}     = Dict{Symbol, Any}() #

    useroperators::Dict{Symbol, Any} = Dict{Symbol, Any}() # Advanced users define ops?
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :multisetsorts, :productsorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts, :useroperators)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

"Return dictionary of `UserSort`"
usersorts(dd::DeclDict)      = dd.usersorts
"Return dictionary of `UserOperator`"
useroperators(dd::DeclDict)  = dd.useroperators
"Return dictionary of `VariableDecl`"
variabledecls(dd::DeclDict)  = dd.variabledecls
"Return dictionary of `NamedSort`"
namedsorts(dd::DeclDict)     = dd.namedsorts
"Return dictionary of `ArbitrarySort`"
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
"Return dictionary of `PartitionSort`"
partitionsorts(dd::DeclDict) = dd.partitionsorts
"Return dictionary of `NamedOperator`"
namedoperators(dd::DeclDict) = dd.namedoperators
"Return dictionary of `ArbitraryOperator`"
arbitraryops(dd::DeclDict)   = dd.arbitraryoperators
"Return dictionary of partitionops (`PartitionElement`)"
partitionops(dd::DeclDict)   = dd.partitionops
"Return dictionary of `FEConstant`"
feconstants(dd::DeclDict)    = dd.feconstants

"Return dictionary of `MultisetSort`"
multisetsorts(dd::DeclDict)    = dd.multisetsorts
"Return dictionary of `ProdictSort`"
productsorts(dd::DeclDict)    = dd.productsorts

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
        values(multisetsorts(dd)),
        values(productsorts(dd)),

        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),

        values(usersorts(dd)),
        values(useroperators(dd)),
    ])
end

"""
    has_key(dd::DeclDict, dict, key::Symbol) -> Bool
Where `dict` is the access method for a dictionary in `DeclDict`.
"""
has_key(dd::DeclDict, dict, key::Symbol)   = haskey(dict(dd),key)

has_variabledecl(dd::DeclDict, id::Symbol)   = has_key(dd, variabledecls, id)
has_namedsort(dd::DeclDict, id::Symbol)      = has_key(dd, namedsorts, id)
has_arbitrarysort(dd::DeclDict, id::Symbol)  = has_key(dd, arbitrarysorts, id)
has_partitionsort(dd::DeclDict, id::Symbol)  = has_key(dd, partitionsorts, id)

has_multisetsort(dd::DeclDict, id::Symbol)   = has_key(dd, mutisetsorts, id)
has_productsort(dd::DeclDict, id::Symbol)    = has_key(dd, productsorts, id)

has_namedop(dd::DeclDict, id::Symbol)        = has_key(dd, namedoperators, id)
has_arbitraryop(dd::DeclDict, id::Symbol)    = has_key(dd, arbitraryops, id)
has_partitionop(dd::DeclDict, id::Symbol)    = has_key(dd, partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)     = has_key(dd, feconstants, id)
has_usersort(dd::DeclDict, id::Symbol)       = has_key(dd, usersorts, id)
has_useroperator(dd::DeclDict, id::Symbol)   = has_key(dd, useroperators, id)

"Lookup variable with `id` in DeclDict."
function variable(dd::DeclDict, id::Symbol)
    if has_variabledecl(dd, id)
        return @inbounds variabledecls(dd)[id]
    else
        error("no varibledecl[$id] found! DeclDict = $(repr(dd))")
    end
end

"Lookup namedsort with `id` in DeclDict."
namedsort(dd::DeclDict, id::Symbol)      = namedsorts(dd)[id]
"Lookup arbitrarysort with `id` in DeclDict."
arbitrarysort(dd::DeclDict, id::Symbol)  = arbitrarysorts(dd)[id]
"Lookup partitionsort with `id` in DeclDict."
partitionsort(dd::DeclDict, id::Symbol)  = partitionsorts(dd)[id]

"Lookup multisetsort with `id` in DeclDict."
multisetsort(dd::DeclDict, id::Symbol)  = multisetsorts(dd)[id]
"Lookup productsort with `id` in DeclDict."
productsort(dd::DeclDict, id::Symbol)   = productsorts(dd)[id]

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
_sort_dictionaries() = (:namedsorts, :usersorts, :partitionsorts,
                        :arbitrarysorts, multisetsorts, productsorts)
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

Operator Declarations include: :namedoperator, :feconstant, :partitionelement, :arbitraryoperator
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
    for dict in _ops(dd) # Look through all the dictionaries.
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

#! 2025-07-16 JDH moved ParseContext
# Add the dictionary accessor argument after sorts are dispatchable.

"Look for matching value in dictionary, return key or nothing."
function find_valuekey(d::AbstractDict, x, func=identity)
    id = nothing
    for (k,v) in pairs(skipmissing(d))
        if func(v) == x # Apply `func` to each value, looking for a match.
            id = k
            @warn "found existing $id" x
            break
        end
    end
    return id#  Key of matched value or nothing.
end
