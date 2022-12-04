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

include("TestUtils.jl")
using .TestUtils

"Return true if one of the GROUP environment variable's values if found in 'v'."
select(v...) = any(any(==(g), v) for g in split(GROUP))

if select("None")
    return
end

#############################################################################
@time "ALL TESTS" begin

# Check for ambiguous methods.
@time "ambiguous" begin
    ambiguous = detect_ambiguities(PNML, PnmlTypeDefs, PnmlIDRegistrys; recursive=true)
    @test length(ambiguous) == 0
    foreach(ambiguous) do amb
        @show amb
    end
end
# Check for unbound type parameters.
@time "unbound" begin
    unbound = detect_unbound_args(PNML, PnmlTypeDefs, PnmlIDRegistrys; recursive=true)
    @test length(unbound) == 0
    foreach(unbound) do unb
        @show unb
    end
end
@testset verbose=true "PNML.jl" begin
    if select("All", "Base")
        #!TestUtils.header("Base")
        @time "typedefs" @safetestset "typedefs"  begin include("Core/typedefs.jl") end
        @time "registry" @safetestset "registry"  begin include("Core/idregistry.jl") end
        @time "utils"    @safetestset "utils"     begin include("Core/utils.jl") end
    end
    if select("All", "Core")
        #!header("Core")
        @time "labels"       @safetestset "labels"       begin include("Core/labels.jl") end
        @time "graphics"     @safetestset "graphics"     begin include("Core/graphics.jl") end
        @time "toolspecific" @safetestset "toolspecific" begin include("Core/toolspecific.jl") end
        @time "exceptions"   @safetestset "exceptions"   begin include("Core/exceptions.jl") end
        @time "nodes"        @safetestset "nodes"        begin include("Core/nodes.jl") end
        @time "pages"        @safetestset "pages"        begin include("Core/pages.jl") end
        @time "flatten"      @safetestset "flatten"      begin include("Core/flatten.jl") end
    end
    if select("All", "HighLevel")
        #!header("HighLevel")
        @time "declarations" @safetestset "declarations" begin include("HighLevel/declarations.jl") end
        @time "labels_hl"    @safetestset "labels_hl"    begin include("HighLevel/labels_hl.jl") end
    end
    if select("All", "Parse")
        #!header("Parse")
        #@safetestset "parse_labels" begin include("parse_labels.jl") end
        @time "parse_tree" @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end
    if select("All", "Net")
        #!header("Petri Net")
        @time "document"  @safetestset "document"     begin include("Core/document.jl") end
        @time "simplenet" @safetestset "simplenet"    begin include("PetriNets/simplenet.jl") end
        @time "rate"      @safetestset "rate"         begin include("PetriNets/rate.jl") end
    end
    if select("All", "Examples")
        #!header("Examples")
        @time "example file" @safetestset "example file" begin include("parse_examples.jl") end
    end
    if select("All", "Doc")
        #!header("Doctests")
        @time "doctest" @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
