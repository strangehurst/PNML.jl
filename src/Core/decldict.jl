@kwdef struct DeclDict
    namedoperators::Dict{Symbol, NamedOperator} = Dict{Symbol, NamedOperator}()
    namedsorts::Dict{Symbol, NamedSort} = Dict{Symbol, NamedSort}()
    partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}()
    variabledecls::Dict{Symbol, VariableDeclaration} = Dict{Symbol, VariableDeclaration}()

    #! partitionops::Dict{Symbol,PartitionOp} = Dict{Symbol,PartitionOp}() # partitionelement
    #feconstants::Dict{Symbol, Union{String,SubString{String}}} = Dict{Symbol, Union{String,SubString{String}}}()
    feconstants::Dict{Symbol, FEConstant} = Dict{Symbol, FEConstant}()
end
decldict(netid::Symbol) = haskey(TOPDECLDICTIONARY, netid) ? TOPDECLDICTIONARY[netid] : error("$netid not in TOPDECLDICTIONARY")

Base.isempty(dd::DeclDict) = all(f->isempty(getproperty(dd, f)),
    [:namedsorts, :partitionsorts, :variabledecls, :namedoperators, :feconstants])

named_op(dd::DeclDict, id::Symbol)      = dd.namedoperators[id]
named_sort(dd::DeclDict, id::Symbol)    = dd.namedsorts[id]
variable(dd::DeclDict, id::Symbol)      = dd.variabledecls[id]
partitionsort(dd::DeclDict, id::Symbol) = dd.partitionsorts[id]
#partitionop(dd::DeclDict, id::Symbol)  = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)    = dd.feconstants[id]

has_named_op(dd::DeclDict, id::Symbol)      = haskey(dd.namedoperators, id)
has_named_sort(dd::DeclDict, id::Symbol)    = haskey(dd.namedsorts, id)
has_variable(dd::DeclDict, id::Symbol)      = haskey(dd.variabledecls, id)
has_partitionsort(dd::DeclDict, id::Symbol) = haskey(dd.partitionsorts, id)
#has_partitionop(dd::DeclDict, id::Symbol)  = haskey(dd.partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)    = haskey(dd.feconstants, id)

function declarations(dd::DeclDict)
    # AbstractDeclaration[d for d in Iterators.flatten([values(dd.namedsorts)...,
    #         values(dd.partitionsorts)...,
    #         values(dd.variables)...,
    #         values(dd.operators)...])]
    collect(Iterators.flatten([values(dd.namedsorts),
                               values(dd.partitionsorts),
                               values(dd.variabledecls),
                               values(dd.namedoperators)]))
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

    print(io, "PartitionSort[")
    for (k,v) in pairs(dd.partitionsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "VariableDeclaration[")
    for (k,v) in pairs(dd.variabledecls)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "NamedOperator[")
    for (k,v) in pairs(dd.namedoperators)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    #! partitionops:
    print(io, "FEConstant[")
    for (k,v) in pairs(dd.feconstants)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, ")")
end
