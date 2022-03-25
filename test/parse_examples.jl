@testset "AirplaneLD pnml file" begin
    testfile = joinpath(pnml_dir, "AirplaneLD-col-0010.pnml")
    @show typeof(testfile), testfile
    model = parse_file(testfile)
    @test model isa PNML.PnmlModel
    nets = PNML.nets(model)
    @test nets isa Vector{PNML.PnmlNet}
    @test length(nets) == 1
    @test nets[1].pages isa Vector
    @test length(nets[1].pages) == 1
    @test !isempty(nets[1].pages[1].transitions)
    @test !isempty(nets[1].pages[1].arcs)
    @test !isempty(nets[1].pages[1].places)
    @test firstpage(nets[1]) isa PNML.Page
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

