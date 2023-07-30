using PNML
using AbstractTrees, Test, SafeTestsets
using PrettyPrinting
using Documenter
#, LabelledArrays
using JET

const GROUPS = (split ∘ uppercase)(get(ENV, "GROUP", "ALL"))

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

include("TestUtils.jl")
using .TestUtils

"Return true if one of the GROUP environment variable's values is found in 'v'."
select(v...) = any(any(==(g), v) for g in GROUPS)

if select("None")
    return
end

#############################################################################
@time "ALL TESTS" begin

# Check for ambiguous methods.
@time "ambiguous" begin
    ambiguous = detect_ambiguities(PNML; recursive=true)
    for amb in ambiguous
        @show amb
    end
    @test length(ambiguous) == 0
end
# Check for unbound type parameters.
@time "unbound" begin
    unbound = detect_unbound_args(PNML; recursive=true)
    for unb in unbound
        println()
        @show unb
        println()
    end
 #   @test length(unbound) == 0
end

UNDER_CI = (get(ENV, "CI", nothing) == "true")
const noisy::Bool = false
@testset verbose=true failfast=true showtiming=true "PNML.jl" begin
#@testset verbose=true "PNML.jl" begin
    if select("ALL", "BASE")
        noisy && println("BASE")
        @time "typedefs" @safetestset "typedefs"  begin include("typedefs.jl") end
        @time "registry" @safetestset "registry"  begin include("idregistry.jl") end
        @time "utils"    @safetestset "utils"     begin include("utils.jl") end
    end
    if select("ALL", "CORE")
        noisy && println("CORE")
        @time "graphics"     @safetestset "graphics"     begin include("graphics.jl") end
        @time "toolspecific" @safetestset "toolspecific" begin include("toolspecific.jl") end
        @time "labels"       @safetestset "labels"       begin include("labels.jl") end
        @time "nodes"        @safetestset "nodes"        begin include("nodes.jl") end
        @time "pages"        @safetestset "pages"        begin include("pages.jl") end
        @time "exceptions"   @safetestset "exceptions"   begin include("exceptions.jl") end
        @time "flatten"      @safetestset "flatten"      begin include("flatten.jl") end
    end
    if select("ALL", "HIGHLEVEL")
        noisy && println("HIGHLEVEL")
        @time "declarations" @safetestset "declarations" begin include("declarations.jl") end
        @time "labels_hl"    @safetestset "labels_hl"    begin include("labels_hl.jl") end
    end

    if select("ALL", "PARSE") # Overall full flow test
        noisy && println("PARSE")
        @time "document"  @safetestset "document"     begin include("document.jl") end
        @time "parse_tree" @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end
    if select("ALL", "NET")
        noisy && println("NET")
        @time "rate"      @safetestset "rate"         begin include("rate.jl") end
        @time "simplenet" @safetestset "simplenet"    begin include("simplenet.jl") end
    end
    if select("ALL", "DOC")
        @time "doctest" @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
