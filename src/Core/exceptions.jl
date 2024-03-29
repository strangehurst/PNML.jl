"""
$(TYPEDEF)
"""
abstract type PnmlException <: Exception end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Use exception to allow dispatch and additional data presentation to user.
"""
struct MissingIDException <: PnmlException
    msg::String
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct MalformedException <: PnmlException
    msg::String
end

function Base.showerror(io::IO, exc::MissingIDException)
    print(io, "MissingIDException: ", exc.msg)
end

function Base.showerror(io::IO, exc::MalformedException)
    print(io, "MalformedException: ", exc.msg)
end
