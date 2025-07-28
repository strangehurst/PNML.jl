#!--------------------
#! see decldictcore.jl for  struct DeclDict
#!--------------------

function Base.show(io::IO, dd::DeclDict)

    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)
    iio = inc_indent(io)

    print(io,  indent(io), "UserSort[")
    print(iio, keys(usersorts(dd)))
    # for (k,v) in pairs(usersorts(dd))
    #     print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    # end
    println(io, "]")

    print(io, indent(io), "NamedSort[")
    print(iio, keys(namedsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "NamedOperator[")
    print(iio, keys(namedoperators(dd)))
    println(io, "]")

    print(io,  indent(io), "VariableDeclaration[")
    print(iio, keys(variabledecls(dd)))
    println(io, "]")

    print(io,  indent(io), "ProductSort[")
    print(iio, keys(productsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "PartitionSort[")
    print(iio, keys(partitionsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "PartitionElement[")
    print(iio, keys(partitionops(dd)))
    println(io, "]")

    print(io,  indent(io), "FEConstant[")
    print(iio, keys(feconstants(dd)))
    println(io, "]")

    print(io, ")")
end
