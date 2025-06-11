#!--------------------
#! see decldictcore.jl for  struct DeclDict
#!--------------------

function Base.show(io::IO, dd::DeclDict)

    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)  # one indent
    iio = inc_indent(io) # two indents
    print(io, "NamedSort[")
    print(io, keys(namedsorts(dd)))
    # for (k,v) in pairs(namedsorts(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    # end
    println(io, "]")

    print(io, "NamedOperator[")
    print(io, keys(namedoperators(dd)))
    # for (k,v) in pairs(namedoperators(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    # end
    println(io, "]")

    print(io, "VariableDeclaration[")
    print(io, keys(variabledecls(dd)))
   # for (k,v) in pairs(variabledecls(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => "); show(io, v)
    # end
    println(io, "]")

    print(io, "PartitionSort[")
    print(io, keys(partitionsorts(dd)))
    # for (k,v) in pairs(partitionsorts(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    #     # Does/should this also print the partition elements
    # end
    println(io, "]")

    print(io, "PartitionElement[")
    print(io, keys(partitionops(dd)))
    # for (k,v) in pairs(partitionops(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); println(io, " => ", v)
    #     #@error  Iterators.map(pid, sortelements(v.terms))
    # end
    println(io, "]")

    print(io, "FEConstant[")
    print(io, keys(feconstants(dd)))
    # for (k,v) in pairs(feconstants(dd))
    #     print(iio, '\n', indent(iio));
    #     show(io, k); print(io, " => "); show(io, v)
    # end
    println(io, "]")

    print(io, "UserSort[")
    print(io, keys(usersorts(dd)))
    # for (k,v) in pairs(usersorts(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    # end
    println(io, "]")

    print(io, ")")
end
