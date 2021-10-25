
@testset "example pnml" begin
    pn = parse_file(joinpath(pnml_dir, "AirplaneLD-col-0010.pnml"))
    # N
    #printnode(pn) # Too much to display for every test!
    #@test pn[:tag] == :pnml #parse_file now returns a PNML.Document
    @test pn isa PNML.Document
    nets = PNML.nets(pn)
    @test nets isa Vector
    @test length(nets) == 1
    @test nets[1][:pages] isa Vector
    @test length(nets[1][:pages]) == 1
    @test !isempty(nets[1][:pages][1][:trans])
    @test !isempty(nets[1][:pages][1][:arcs])
    @test !isempty(nets[1][:pages][1][:places])

    if PRINT_PNML
        #@show keys(pn)
        @show keys(nets)
        @show keys(nets[1])
        @show keys(nets[1][:pages])
        @show keys(nets[1][:pages][1])
        foreach(nets) do net
            @show keys(net)
            foreach(net[:pages]) do page
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

