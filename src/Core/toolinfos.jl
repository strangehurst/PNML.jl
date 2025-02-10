"""
$(TYPEDEF)
$(TYPEDFIELDS)

ToolInfo holds a <toolspecific> tag.

It wraps a iteratable collection (currently vector) of well formed elements
parsed into [`AnyElement`](@ref)s for use by anything that understands
toolname, version tool specifics.
"""
@auto_hash_equals struct ToolInfo
    toolname::String
    version::String
    infos::Vector{AnyElement}
end

"Name of tool to for this tool specific information element."
name(ti::ToolInfo) = ti.toolname
"Version of tool for this tool specific information element."
version(ti::ToolInfo) = ti.version
"Content of a ToolInfo."
infos(ti::ToolInfo) = ti.infos::Vector{AnyElement}

##Base.eltype(ti::ToolInfo) = eltype(infos(ti))

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    print(io, "ToolInfo[")
    for ti in toolvector
        show(io, ti); print(io, ", ")
    end
    print(io, "]")
end

function Base.show(io::IO, ti::ToolInfo)
    print(io, indent(io), "ToolInfo(")
    show(io, name(ti)); print(io, ", ");
    show(io, version(ti)); print(io, ", [");
    println(io);
    io = inc_indent(io)
    for i in infos(ti)
        show(IOContext(io, :typeinfo=>AnyElement), i)
        println(io, ",")
    end
    print(io, "])")
end

###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content.
Combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics{T <: Float32} <: AbstractPnmlTool
    positions::Vector{Coordinate{T}}
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics{T}() where {T <: Float32} = TokenGraphics{T}(Coordinate{T}[])

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "TokenGraphics(", tg.positions, ")")
end

###############################################################################

"""
has_toolinfo(infos, toolname[, version]) -> Bool

Does any toolinfo in iteratable `infos` have a matching `toolname`, and a matching `version` (if it is provided).
`toolname` and `version` will be turned into `Regex`s to match against each `ToolInfo` in the `infos` collection.
"""
function has_toolinfo end

function has_toolinfo(infos, toolname)
    has_toolinfo(infos, Regex(toolname))
end

function has_toolinfo(infos, toolname, version)
    has_toolinfo(infos, Regex(toolname), Regex(version))
end

function has_toolinfo(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    any(infos) do tool
       !isnothing(match(namerex, name(tool))) &&
        !isnothing(match(versionrex, version(tool)))
    end
end

"""
    get_toolinfo(infos, toolname[, version]) -> Maybe{ToolInfo}

Return first toolinfo in iteratable collection `infos` having a matching toolname and version.
See [`has_toolinfo`](@ref)

    get_toolinfo(ti::ToolInfo, toolname[, version]) -> Maybe{ToolInfo}

Return `ti` if `toolname` and `version` match, `nothing` otherwise.
"""
function get_toolinfo end

get_toolinfo(ti::ToolInfo, name::AbstractString) = get_toolinfo(ti, Regex(name))
get_toolinfo(ti::ToolInfo, name::AbstractString, version::AbstractString) =
    get_toolinfo(ti, Regex(name), Regex(version))
get_toolinfo(ti::ToolInfo, name::AbstractString, versionrex::Regex) =
    get_toolinfo(ti, Regex(name),  versionrex)

get_toolinfo(ti::ToolInfo, namerex::Regex, versionrex::Regex=r"^.*$") =
    _match(ti, namerex, versionrex) ? ti : nothing

# Collections
get_toolinfo(infos, name::AbstractString, version::AbstractString) =
    get_toolinfo(infos, Regex(name), Regex(version))

get_toolinfo(infos, name::AbstractString, versionrex::Regex) =
    get_toolinfo(infos, Regex(name), versionrex)

function get_toolinfo(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    first(get_toolinfos(infos, namerex, versionrex))
end

"""
    get_toolinfos(infos, toolname::Regex[, version::Regex]) -> Iterator

Return iterator over toolinfos matching toolname and version regular expressions.
"""
function get_toolinfos(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    Iterators.filter(ti -> _match(ti, namerex, versionrex), infos)
end

"""
    _match(ti::ToolInfo, name::AbstractString) -> Bool
    _match(ti::ToolInfo, name::String, version::String) -> Bool
    _match(ti::ToolInfo, namerex::Regex, versionrex::Regex) -> Bool

Return `true` if both toolname and version match. Default is any version.
"""
function _match end
_match(ti::ToolInfo, name::AbstractString) = _match(ti.info, Regex(name))
_match(ti::ToolInfo, name::AbstractString, version::AbstractString) = _match(ti.inf, Regex(name), Regex(version))

function _match(ti::ToolInfo, namerex::Regex, versionrex::Regex = r"^.*$")
    match_name = match(namerex, name(ti))
    match_version = match(versionrex, version(ti))
    !isnothing(match_name) && !isnothing(match_version)
end


##################################################################
# Validation, Analysis, Reports, Etc.
##################################################################

"""
    validate_toolinfos(infos, dd) -> Bool

Validate each `ToolInfo` in the iterable `infos` collection.

Note that each info may contain any well-formed XML. That XML for other tools must be ignored.
Any info for this tool will have deeper validation implemented.
"""
function validate_toolinfos(tools)
    isnothing(tools) && return true
    for tool in tools
        @show tool #todo more tests tan this.
    end
    return true
end
function list_toolinfos(tools)   isnothing(tools) && return true
    if isnothing(tools)
        for tool in tools
            @show tool
        end
    end
end
