using PNML #, EzXML
using AbstractTrees, Test, SafeTestsets
using PrettyPrinting
using IfElse
# Run the tests embedded in docstrings.
using Documenter, LabelledArrays
using JET

const GROUP = get(ENV, "GROUP", "All")

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

module TestUtils
using EzXML

"Turn string into XML node."
to_node(s::AbstractString) = root(EzXML.parsexml(s))

const PRINT_PNML = parse(Bool, get(ENV, "PRINT_PNML", "true"))

"Print `node` prepended by optional label string."
function printnode(io::IO, node; label=nothing, kw...)
    if PRINT_PNML
        !isnothing(label) && print(io, label, " ")
        show(io, MIME"text/plain"(), node)
        println(io, "\n")
    end
end
function printnode(n; kw...)
    printnode(stdout, n; kw...)
end

function printnodeln(io::IO, n; kw...)
    printnode(io, n; kw...)
    PRINT_PNML && println(io)
end

const VERBOSE_PNML = parse(Bool, get(ENV, "VERBOSE_PNML", "true"))

header(s) = if VERBOSE_PNML
    println("##### ", s)
end

const SHOW_SUMMARYSIZE = parse(Bool, get(ENV, "SHOW_SUMMARYSIZE", "false"))

function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

export PRINT_PNML, VERBOSE_PNML, SHOW_SUMMARYSIZE,
    to_node, printnode, header, showsize

end # module TestUtils

using .TestUtils

"Return true if one of the GROUP environment variable's values if found in 'v'."
select(v...) = any(any(==(g), v) for g in split(GROUP))

if select("None")
    return
end

@testset verbose=false "PNML.jl" begin
    if select("All", "Base")
        TestUtils.header("Base")
        @safetestset "typedefs"     begin include("Core/typedefs.jl") end
        @safetestset "idreg"        begin include("Core/idregistry.jl") end
        @safetestset "utils"        begin include("Core/utils.jl") end
    end
    if select("All", "Core")
        header("Core")
        @safetestset "nodes"        begin include("Core/nodes.jl") end
        @safetestset "graphics"     begin include("Core/graphics.jl") end
        @safetestset "labels"       begin include("Core/labels.jl") end
        @safetestset "toolspecific" begin include("Core/toolspecific.jl") end
        @safetestset "exceptions"   begin include("Core/exceptions.jl") end
        @safetestset "pages"        begin include("Core/pages.jl") end
        @safetestset "flatten"      begin include("Core/flatten.jl") end
    end
    if select("All", "HighLevel")
        header("HighLevel")
        @safetestset "declarations" begin include("HighLevel/declarations.jl") end
    end
    if select("All", "Parse")
        header("Parse")
        @safetestset "parse_labels" begin include("parse_labels.jl") end
        @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end
    if select("All", "Examples")
        header("Examples")
        @safetestset "example file" begin include("parse_examples.jl") end
    end
    if select("All", "Net")
        header("Net")
        @safetestset "document"     begin include("Core/document.jl") end
        @safetestset "simplenet"    begin include("PetriNets/simplenet.jl") end
    end
    if select("All", "Doc")
        header("Doctests")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
