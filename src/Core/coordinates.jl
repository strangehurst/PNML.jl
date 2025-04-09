"""
$(TYPEDEF)
$(TYPEDFIELDS)

Cartesian Coordinate are positive decimals. Ranges from 0 to 999.9.
"""
struct Coordinate{T <: Float32} #! is decimal 0 to 999.9 in Schema
    x_::T
    y_::T
end

"""
Construct a Coordinate from mixed Int, Float64.
"""
Coordinate(x::T1, y::T2) where {T1 <: Number, T2 <: Number} =
            Coordinate(convert(coordinate_value_type(), x),
                       convert(coordinate_value_type(), y))

coordinate_type(::Type{T}) where {T <: PnmlType} = Coordinate{coordinate_value_type(T)}
coordinate_value_type() = Float32
coordinate_value_type(::Type) = Float32
Base.eltype(::Coordinate{T}) where {T<:Number} = T
x(c::Coordinate) = c.x_
y(c::Coordinate) = c.y_
Base.:(==)(l::Coordinate, r::Coordinate) = x(l) == x(r) && y(l) == y(r)

function Base.show(io::IO, c::Coordinate)
    #compact = get(io, :compact, false)::Bool
    print(io, "Coordinate(", x(c), ", ", y(c), ")")
end
