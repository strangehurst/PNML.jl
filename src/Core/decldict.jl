"""
    DeclDict

Collection of Declaration dictionaries.
"""
@kwdef struct DeclDict
    #TODO tuple(vd::VariableDeclaration, x::typeof(sortof(vd)))
    #todo Each VariableDeclaration is a single data item, tuple(decl, instance_of_sort)
    #todo the sort is the part that is shared and should be de-duplicated.
    variabledecls::Dict{Symbol, VariableDeclaration} = Dict{Symbol, VariableDeclaration}()

    namedsorts::Dict{Symbol, NamedSort} = Dict{Symbol, NamedSort}()
    arbitrarysorts::Dict{Symbol, ArbitrarySort} = Dict{Symbol, ArbitrarySort}()
    partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}()

    # useroperator refers to a OperatorDeclaration by name.
    # todo use flattened iterator over all OperatorDeclarations
    # OperatorDecls include: namedoperator, feconstant, partition element, et al.
    # namedoperators are used to access built-in operators
    namedoperators::Dict{Symbol, NamedOperator} = Dict{Symbol, NamedOperator}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol,PartitionElement} = Dict{Symbol,PartitionElement}()
    # FEConstants are 0-ary OperatorDeclarations.
    # The only explicit attributes are id symbol and name string.
    # We record an optional partition id
    feconstants::Dict{Symbol, FEConstant} = Dict{Symbol, FEConstant}()
    arbitraryoperators::Dict{Symbol, ArbitraryOperator} = Dict{Symbol, ArbitraryOperator}()
end

"""
    decldict(netid::Symbol) -> DeclDict

Access global `DeclDict` for the `PnmlNet` with `netid` or `error()`.
"""
function decldict(netid::Symbol)
    haskey(TOPDECLDICTIONARY, netid) ? TOPDECLDICTIONARY[netid] : error("$netid not in TOPDECLDICTIONARY")
end

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) =
    all(f->isempty(getproperty(dd, f)), (:namedsorts, :namedoperators, :variabledecls, :partitionsorts, :partitionops, :feconstants))
Base.length(dd::DeclDict) =
    sum(f->length(getproperty(dd, f)), (:namedsorts, :namedoperators, :variabledecls, :partitionsorts, :partitionops, :feconstants))

named_op(dd::DeclDict, id::Symbol)      = dd.namedoperators[id]
arbitrary_op(dd::DeclDict, id::Symbol)  = dd.arbitraryoperators[id]
named_sort(dd::DeclDict, id::Symbol)    = dd.namedsorts[id]
arbitrary_sort(dd::DeclDict, id::Symbol) = dd.arbitarysorts[id]
variable(dd::DeclDict, id::Symbol)      = dd.variabledecls[id]
partitionsort(dd::DeclDict, id::Symbol) = dd.partitionsorts[id]
partitionop(dd::DeclDict, id::Symbol)   = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)    = dd.feconstants[id]

has_named_op(dd::DeclDict, id::Symbol)      = haskey(dd.namedoperators, id)
has_named_sort(dd::DeclDict, id::Symbol)    = haskey(dd.namedsorts, id)
has_arbitrary_op(dd::DeclDict, id::Symbol)   = haskey(dd.arbitraryoperators, id)
has_arbitrary_sort(dd::DeclDict, id::Symbol) = haskey(dd.arbitrarysorts, id)
has_variable(dd::DeclDict, id::Symbol)      = haskey(dd.variabledecls, id)
has_partitionsort(dd::DeclDict, id::Symbol) = haskey(dd.partitionsorts, id)
has_partitionop(dd::DeclDict, id::Symbol)   = haskey(dd.partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)    = haskey(dd.feconstants, id)

function declarations(dd::DeclDict)
    Iterators.flatten([
        values(dd.namedsorts),
        values(dd.namedoperators),
        values(dd.partitionsorts),
        values(dd.partitionops),
        values(dd.feconstants),
        values(dd.variabledecls),
                               ])
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
"Return operator dictionary containing `id`."
_get_op_dict(dd::DeclDict, id::Symbol) = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))

"Return operator with `id`. Operators include: `NamedOperator`, `FEConstant`, `PartitionElement`."
function operator(dd::DeclDict, id::Symbol)
    @show dict = _get_op_dict(dd, id)
    #@show dict = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))
    @show op = dict[id]
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


    print(io, ")")
end
