using PNML
using AbstractTrees, Test, SafeTestsets
using PrettyPrinting
using Documenter
#, LabelledArrays
using JET

@info "Pkg.test ARGS" ARGS

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

include("TestUtils.jl")
using .TestUtils

"Return true if one of `v` is found in `ARGS` or `ARGS` is empty."
select(v...) = length(ARGS) == 0 || any(∈(ARGS), v)

if select("none", "NONE")
    return
end

#############################################################################
@time "TESTS" begin

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
        @warn "unbound" unb
    end
    @test length(unbound) == 0
end

UNDER_CI = (get(ENV, "CI", nothing) == "true")

@testset verbose=true failfast=true showtiming=true "PNML.jl" begin
    if select("ALL", "BASE")
        println("BASE")
        @safetestset "typedefs"  begin include("typedefs.jl") end
        @safetestset "registry"  begin include("idregistry.jl") end
        @safetestset "utils"     begin include("utils.jl") end
    end
    if select("ALL", "CORE")
        println("CORE")
        @safetestset "graphics"     begin include("graphics.jl") end
        @safetestset "toolspecific" begin include("toolspecific.jl") end
        @safetestset "labels"       begin include("labels.jl") end
        @safetestset "nodes"        begin include("nodes.jl") end
        @safetestset "pages"        begin include("pages.jl") end
        @safetestset "exceptions"   begin include("exceptions.jl") end
        @safetestset "flatten"      begin include("flatten.jl") end
    end
    if select("ALL", "HIGHLEVEL")
        println("HIGHLEVEL")
        @safetestset "declarations" begin include("declarations.jl") end
        @safetestset "sorts"        begin include("sort.jl") end
        @safetestset "labels_hl"    begin include("labels_hl.jl") end
    end

    if select("ALL", "PARSE") # Overall full flow test
        println("PARSE")
        @safetestset "document"     begin include("document.jl") end
        @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end
    if select("ALL", "NET")
        println("NET")
        @safetestset "rate"         begin include("rate.jl") end
        @safetestset "simplenet"    begin include("simplenet.jl") end
    end
    if select("ALL", "DOC")
        println("DOC")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
