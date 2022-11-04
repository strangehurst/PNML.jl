using PNML, EzXML, ..TestUtils, JET
using PNML: firstpage, parse_file, PnmlNet, Page

header("Exanples")

@testset "AirplaneLD pnml file" begin
    pnml_dir = joinpath(@__DIR__, "data")
    testfile = joinpath(pnml_dir, "AirplaneLD-col-0010.pnml")
    @show testfile
    model = parse_file(testfile)
    @test_call  parse_file(testfile)

    @test model isa PNML.PnmlModel
    @test_call PNML.nets(model)
    netvec = PNML.nets(model)
    #@show typeof(netvec)
    @test netvec isa Vector{Any}
    @test length(netvec) == 1
    #@show typeof(netvec[1])
    @test netvec[1] isa PnmlNet
    @test netvec[1] isa PnmlNet{<:PnmlType}
    @test netvec[1].pages isa Vector{<:Page}
    @test length(netvec[1].pages) == 1
    @test !isempty(netvec[1].pages[1].transitions)
    @test !isempty(netvec[1].pages[1].arcs)
    @test !isempty(netvec[1].pages[1].places)
    @test firstpage(netvec[1]) isa PNML.Page
    #=
    Decend and print. Needs update.
    if PRINT_PNML
        #@show keys(pn)
        @show keys(nets)
        @show keys(nets[1])
        @show keys(nets[1].pages)
        @show keys(nets[1].pages[1])
        foreach(nets) do net
            @show keys(net)
            foreach(net.pages) do page
                @show keys(page)
                for (key,value) in pairs(page)
                    if value isa Symbol
                        @show key,value
                    elseif !isnothing(value)
                        @show key, keys(value)
                    end
                end
            end
        end
        #dump(pn;maxdepth=5)
    end
    =#
end
#=
@testset "clever trick" begin
    """
    generator of pairs from SBML
    """
    initial_amounts(m::PNML.Model; para1 = false) = (
    k => if !isnothing(s.initial_amount)
        s.initial_amount[1]
    elseif para1 &&
           !isnothing(s.initial_concentration) &&
           haskey(m.compartments, s.compartment) &&
           !isnothing(m.compartments[s.compartment].size)
        s.initial_concentration[1] * m.compartments[s.compartment].size
    else
        nothing
    end for (k, s) in m.species
)
end
=#
