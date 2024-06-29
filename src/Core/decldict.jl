"""
    DeclDict

Collection of Declaration dictionaries.
"""
@kwdef struct DeclDict
    # TODO tuple(vd::VariableDeclaration, x::typeof(sortof(vd)))
    # TODO Each VariableDeclaration is a single data item, tuple(decl, instance_of_sort)
    # TODO the sort is the part that is shared and should be de-duplicated.
    variabledecls::Dict{Symbol, VariableDeclaration} = Dict{Symbol, VariableDeclaration}()

    namedsorts::Dict{Symbol, NamedSort} = Dict{Symbol, NamedSort}()
    arbitrarysorts::Dict{Symbol, ArbitrarySort} = Dict{Symbol, ArbitrarySort}()
    partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}()

    # useroperator refers to a OperatorDeclaration by name.
    # todo use flattened iterator over all OperatorDeclarations
    # OperatorDecls include: namedoperator, feconstant, partition element, et al.
    # namedoperators are used to access built-in operators
    namedoperators::Dict{Symbol, NamedOperator} = Dict{Symbol, NamedOperator}()
    arbitraryoperators::Dict{Symbol, ArbitraryOperator} = Dict{Symbol, ArbitraryOperator}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol,PartitionElement} = Dict{Symbol,PartitionElement}()
    # FEConstants are 0-ary OperatorDeclarations.
    # The only explicit attributes are id symbol and name string.
    # We record an optional partition id
    feconstants::Dict{Symbol, FEConstant} = Dict{Symbol, FEConstant}()

    # Allows using an IDREF symbol as a network-level "global".
    # Useful for non-high-level networks that mimic HLNets to share implementation.
    # Long way of saying generic? (in what sense generic?)
    usersorts::Dict{Symbol, UserSort} = Dict{Symbol, UserSort}()
end

"""
    decldict(netid::Symbol) -> DeclDict

Access global `DeclDict` for the `PnmlNet` with `netid`.
"""
function decldict(netid::Symbol)
    haskey(TOPDECLDICTIONARY, netid) ? TOPDECLDICTIONARY[netid] :
        error(lazy"$(repr(netid)) not in TOPDECLDICTIONARY: $(collect(keys(TOPDECLDICTIONARY)))")
end
_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

variabledecls(dd::DeclDict)  = dd.variabledecls
namedsorts(dd::DeclDict)     = dd.namedsorts
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
partitionsorts(dd::DeclDict) = dd.partitionsorts
namedoperators(dd::DeclDict) = dd.namedoperators
arbitrary_ops(dd::DeclDict)  = dd.arbitraryoperators
partitionops(dd::DeclDict)   = dd.partitionops
feconstants(dd::DeclDict)    = dd.feconstants

usersorts(dd::DeclDict)      = dd.usersorts

"""
    declarations(dd::DeclDict) -> Iterator
Return an iterator over all the declaration dictionaries' values.
Flattens iterators: variabledecls, namedsorts, arbitrarysorts, partitionsorts, partitionops,
namedoperators, arbitrary_ops, feconstants, usersorts.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitrary_ops(dd)),
        values(feconstants(dd)),
        values(usersorts(dd)),                               ])
end

has_variable(dd::DeclDict, id::Symbol)       = haskey(variabledecls(dd), id)
has_named_sort(dd::DeclDict, id::Symbol)     = haskey(namedsorts(dd), id)
has_arbitrary_sort(dd::DeclDict, id::Symbol) = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_named_op(dd::DeclDict, id::Symbol)       = haskey(namedoperators(dd), id)
has_arbitrary_op(dd::DeclDict, id::Symbol)   = haskey(arbitraryoperators(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)

has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)

variable(dd::DeclDict, id::Symbol)       = dd.variabledecls[id]
named_sort(dd::DeclDict, id::Symbol)     = dd.namedsorts[id]
arbitrary_sort(dd::DeclDict, id::Symbol) = dd.arbitrarysorts[id]
partitionsort(dd::DeclDict, id::Symbol)  = dd.partitionsorts[id]
named_op(dd::DeclDict, id::Symbol)       = dd.namedoperators[id]
arbitrary_op(dd::DeclDict, id::Symbol)   = dd.arbitraryoperators[id]
partitionop(dd::DeclDict, id::Symbol)    = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)     = dd.feconstants[id]

usersort(dd::DeclDict, id::Symbol)       = dd.usersorts[id]


"""
    fill_nonhl!(dd::DeclDict; ids::Tuple) -> nothing

Fill a DeclDict with values needed by non-high-level networks.

    NamedSort(:integer, "Integer", IntegerSort(); ids)
    NamedSort(:natural, "Natural", NaturalSort(); ids)
    NamedSort(:positive, "Positive", PositiveSort(); ids)
    NamedSort(:real, "Real", RealSort(); ids)
    NamedSort(:dot, "Dot", DotSort(); ids)

    UserSort(:integer; ids)
    UserSort(:natural; ids)
    UserSort(:positive; ids)
    UserSort(:real; ids)
    UserSort(:dot; ids)
"""
function fill_nonhl!(dd::DeclDict; ids::Tuple)
    for (tag, name, sort) in ((:integer, "Integer", IntegerSort()),
                              (:natural, "Natural", NaturalSort()),
                              (:positve, "Positive", PositiveSort()),
                              (:real, "Real", RealSort()),
                              (:dot, "Dot", DotSort()),
                              )

        if !haskey(dd.namedsorts, tag)
            dd.namedsorts[tag] = NamedSort(tag, name, sort; ids)
        end
        if !haskey(dd.usersorts, tag)
            dd.usersorts[tag] = UserSort(tag; ids)
        end
    end
end

#TODO
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
_ops(dd) = Iterators.map(op -> getfield(dd, op), _op_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(values, _ops(dd)))

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

#! Change first to only when de-duplication implementd? as test?
"Return operator dictionary containing key `id`."
_get_op_dict(dd::DeclDict, id::Symbol) = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))

"""
Return operator with `id`. Operators include: `NamedOperator`, `FEConstant`, `PartitionElement`.
"""
function operator(dd::DeclDict, id::Symbol)
    dict = _get_op_dict(dd, id)
    op = dict[id]
    return op
end

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    println("validate declarations")
    return true
end

function Base.show(io::IO, dd::DeclDict)
    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)
    iio = inc_indent(io)
    print(io, "NamedSort[")
    for (k,v) in pairs(dd.namedsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "NamedOperator[")
    for (k,v) in pairs(dd.namedoperators)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "VariableDeclaration[")
    for (k,v) in pairs(dd.variabledecls)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "PartitionSort[")
    for (k,v) in pairs(dd.partitionsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
        # Does/should this also print the partition elements
    end
    println(io, "]")

    print(io, "PartitionElement[")
    for (k,v) in pairs(dd.partitionops)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "FEConstant[")
    for (k,v) in pairs(dd.feconstants)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "UserSort[")
    for (k,v) in pairs(dd.usersorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, ")")
end
