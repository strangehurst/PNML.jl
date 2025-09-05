"""
$(TYPEDEF)
$(TYPEDFIELDS)

Holds a <toolspecific> tag.

It wraps a iteratable collection (currently vector) of well formed elements
parsed into [`AnyElement`](@ref)s for use by anything that understands
toolname, version tool specifics.
"""
@auto_hash_equals fields=toolname,version,infos typearg=true struct ToolInfo{T}
    toolname::String
    version::String
    infos::Vector{T} # Expect content::Vector{AnyElement}
    declarationdicts::DeclDict
end

"Name of tool to for this tool specific information element."
PNML.name(ti::ToolInfo) = ti.toolname

version(ti::ToolInfo) = ti.version

"Content of a ToolInfo."
infos(ti::ToolInfo{T}) where T  = ti.infos

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    print(io, "ToolInfo[")
    io = PNML.inc_indent(io)
    for (n, anye) in enumerate(toolvector)
        n > 1 && print(io, PNML.indent(io))
        show(io, anye);
        length(toolvector) > 1 && n < length(toolvector) && println(io)
    end
    print(io, "]")
end

function Base.show(io::IO, ti::ToolInfo)
    print(io, "ToolInfo(", PNML.name(ti), ", ", version(ti), ", [")
    if length(infos(ti)) == 1
        show(io, first(infos(ti)))
    elseif length(infos(ti)) > 1
        println(io)
        io = PNML.inc_indent(io)
        for (n,info) in enumerate(infos(ti))
            print(io, PNML.indent(io))
            show(io, info)
            length(infos(ti)) > 1 && n < length(infos(ti)) && println(io)
        end
    end
    print(io, "])")
end

###############################################################################

###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content.
Combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics
    positions::Vector{PNML.Coordinate}
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics() = TokenGraphics(PNML.Coordinate[])

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "TokenGraphics(", tg.positions, ")")
end

###############################################################################

"""
has_toolinfo(infos, toolname[, version]) -> Bool

Does any toolinfo in iteratable collection `infos` have a matching `toolname`,
and a matching `version` (if it is provided).
`toolname` and `version` will be turned into `Regex`s
to match against each item in the `infos` collection.
"""
function has_toolinfo end

function has_toolinfo(infos, toolname)
    has_toolinfo(infos, Regex(toolname))
end

function has_toolinfo(infos, toolname, version)
    has_toolinfo(infos, Regex(toolname), Regex(version))
end

function has_toolinfo(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    isnothing(infos) ? false :
    isempty(infos) ? false :
    any(ti -> _match(ti, namerex, versionrex), infos)
    #any(Iterators.filter(ti -> _match(ti, namerex, versionrex), infos))
end

"""
    get_toolinfo(infos, toolname[, version]) -> Maybe{ToolInfo}

Return first toolinfo in iteratable collection `infos` having a matching toolname and version.
See [`has_toolinfo`](@ref).
"""
function get_toolinfo end

# Collections
get_toolinfo(infos, name::AbstractString) = get_toolinfo(infos, Regex(name))
function  get_toolinfo(infos, name::AbstractString, version::AbstractString)
    get_toolinfo(infos, Regex(name), Regex(version))
end
function get_toolinfo(infos, name::AbstractString, versionrex::Regex)
    get_toolinfo(infos, Regex(name), versionrex)
end
function get_toolinfo(infos, namerex::Regex, versionrex::Regex = r"^.*$")
    isempty(infos) && return nothing
    infos = get_toolinfos(infos, namerex, r"^.*$") # filter by toolname regex
    isempty(infos) ? nothing : first(get_toolinfos(infos, namerex, versionrex))
end

"""
    get_toolinfos(infos, toolname::Regex, version::Regex) -> Iterator

`infos` may be a collection of `ToolInfo` or `ToolParser`.
Return iterator over `infos` matching toolname and version regular expressions.
Default version regex matches anything, returning all infos for a tool or all parsers for a tool.
"""
function get_toolinfos(infos, namerex::Regex, versionrex::Regex = r"^.*$")
    #!@show infos namerex versionrex
    Iterators.filter(ti -> _match(ti, namerex, versionrex), infos)
end

"""
    _match(tx, namerex::Regex, versionrex::Regex) -> Bool

Return `true` if both toolname and version match. Default is any version.
Applies to ToolInfo, ToolParser, and other objects with a `name` and `version` method.
"""
function _match(tx::Union{ToolInfo,ToolParser}, namerex::Regex, versionrex::Regex = r"^.*$")
    match_name = match(namerex, PNML.name(tx))
    match_version = match(versionrex, version(tx))
    !isnothing(match_name) && !isnothing(match_version)
end


##################################################################
# Validation, Analysis, Reports, Etc.
##################################################################

"""
    validate_toolinfos(infos, dd) -> Bool

Validate each `ToolInfo` in the iterable `infos` collection.

Note that each info may contain any well-formed XML. That XML for other toolinfos must be ignored.
Any info for this tool will have deeper validation implemented.
"""
function validate_toolinfos(toolinfos)
    isnothing(toolinfos) && return true
    for tool in toolinfos
        @assert tool isa ToolInfo #todo more tests than this.
    end
    return true
end
function list_toolinfos(toolinfos)
    isnothing(toolinfos) && return true
    if isnothing(toolinfos)
        for tool in toolinfos
            @show tool
        end
    end
end
