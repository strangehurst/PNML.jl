const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"
const XMLNode = EzXML.Node

"""
    extract_pnml()

given a filename, `EzXML.Document`, or `EzXML.Node`
returns all of the Pnml nodes.
"""
function extract_pnml end

extract_pnml(fn::AbstractString) =  extract_pnml(readxml(fn))
extract_pnml(doc::EzXML.Document) = extract_pnml(EzXML.root(doc))

function extract_pnml(node::EzXML.Node)
    EzXML.findall("//x:pnml", node, ["x" => pnml_ns])
end

"""
    @xml_str(s)

utility macro for parsing xml strings into node
"""
macro xml_str(s)
    EzXML.parsexml(s).root
end

"""
    @pnml_str(s)

#TODO utility macro for parsing xml strings into symbolics
"""
macro pnml_str(s)
    PNML.parse_str(s)
end

"Parse XML content as a number. First try integer then float."
function number_value(s::AbstractString)
    x = tryparse(Int,s) 
    x = isnothing(x) ?  tryparse(Float64,s) : x
end

"Return up to 1 immediate` child of element `el` that is a `tag`."
function firstchild(tag, el, ns=PNML.pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x"=>ns])
end

"Return vector of 'el` element's immediate children with `tag`."
function allchildren(tag, el, ns=PNML.pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x"=>ns])
end

#-------------------------------------------------------------------
# XML attribute predicates.
has_align(element)       = EzXML.haskey(element, "align")
has_color(element)       = EzXML.haskey(element, "color")
has_declaration(element) = EzXML.haskey(element, "declaration") # UserSort
has_decoration(element)  = EzXML.haskey(element, "decoration")
has_family(element)      = EzXML.haskey(element, "family")
has_gradient_color(element)    = EzXML.haskey(element, "gradient-color")
has_gradient_rotation(element) = EzXML.haskey(element, "gradient-rotation")
has_id(element)          = EzXML.haskey(element, "id")
has_image(element)       = EzXML.haskey(element, "image")
has_name(element)        = EzXML.haskey(element, "name") # declaration tag has name attributes.
has_ref(element)         = EzXML.haskey(element, "ref")
has_rotation(element)    = EzXML.haskey(element, "rotation")
has_shape(element)       = EzXML.haskey(element, "shape")
has_size(element)        = EzXML.haskey(element, "size")
has_source(element)      = EzXML.haskey(element, "source")
has_style(element)       = EzXML.haskey(element, "style")
has_target(element)      = EzXML.haskey(element, "target")
has_tool(element)        = EzXML.haskey(element, "tool")
has_type(element)        = EzXML.haskey(element, "type")
has_value(element)       = EzXML.haskey(element, "value")
has_variabledecl(element) = EzXML.haskey(element, "variabledecl") # Variable
has_refvariable(element) = EzXML.haskey(element, "refvariable") # Variable
has_version(element)     = EzXML.haskey(element, "version")
has_weight(element)      = EzXML.haskey(element, "weight")
has_width(element)       = EzXML.haskey(element, "width")
has_x(element)           = EzXML.haskey(element, "x")
has_xmlns(element)       = EzXML.haskey(element, "xmlns")
has_y(element)           = EzXML.haskey(element, "y")

#-------------------------------------------------------------------
# bindings for viewing tree
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node

#-------------------------------------------------------------------
"Holds a set of pnml id symbols and a lock to allow safe reentrancy."
mutable struct IDRegistry
    ids::Set{Symbol}
    lk::ReentrantLock
end
IDRegistry() = IDRegistry(Set{Symbol}(), ReentrantLock())
const GlobalIDRegistry = IDRegistry()


const DUPLICATE_ID_ACTION=nothing
"""
Use a global configuration to choose what to do when a duplicated pnml node id
has been detected. Default is to do nothing.
There are many pnml files on the internet that have many duplicates.
"""
function duplicate_id_action(id::Symbol)
    DUPLICATE_ID_ACTION === nothing && return
    DUPLICATE_ID_ACTION === :warn && @warn "ID '$(id)' already registered"
    DUPLICATE_ID_ACTION === :error && error("ID '$(id)' already registered in  $(GlobalIDRegistry.ids)")
end


"Register `id` symbol and return the symbol."
register_id(s::AbstractString) = register_id(Symbol(s))
function register_id(id::Symbol)
    global GlobalIDRegistry
    lock(GlobalIDRegistry.lk) do
        id ∈ GlobalIDRegistry.ids && duplicate_id_action(id)
        push!(GlobalIDRegistry.ids, id)
    end
    id
 end

isregistered(s::AbstractString) = isregistered(Symbol(s))
function isregistered(id::Symbol)
    global GlobalIDRegistry
    lock(GlobalIDRegistry.lk) do
        id ∈ GlobalIDRegistry.ids
    end
end

""" reset_registry()

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset_registry()
    global GlobalIDRegistry
    lock(GlobalIDRegistry.lk) do
        empty!(GlobalIDRegistry.ids)
    end
end

function Base.isempty(reg::IDRegistry)
    lock(reg.lk) do
        isempty(reg.ids)
    end
end

#-------------------------------------------------------------------
#TODO: Make global state varaible.
#Count and lock to implement global state."
mutable struct MissingIDCounter
    i::Int
    lk::ReentrantLock
end
MissingIDCounter() = MissingIDCounter(0, ReentrantLock())

#Increment counter and return new value."
function next_missing_id(c::MissingIDCounter)
    lock(c.lk) do
        c.i += 1
    end 
end
