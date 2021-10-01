
const TOPDIR = "/home/jeff/Projects/Resources/PetriNet/PNML"

@testset "example pnml" begin
    pn = parse_file(joinpath(TOPDIR, "examples/AirplaneLD/COLORED/AirplaneLD-col-0010.pnml"))
    #printnode(pn) # Too much to display for every test!
    @test pn[:tag] == :pnml
    @test pn[:nets] isa Vector
    @test length(pn[:nets]) == 1
    @test pn[:nets][1][:pages] isa Vector
    @test length(pn[:nets][1][:pages]) == 1
    @test !isempty(pn[:nets][1][:pages][1][:trans])
    @test !isempty(pn[:nets][1][:pages][1][:arcs])
    @test !isempty(pn[:nets][1][:pages][1][:places])

    if PRINT_PNML
        @show keys(pn)
        @show keys(pn[:nets])
        @show keys(pn[:nets][1])
        @show keys(pn[:nets][1][:pages])
        @show keys(pn[:nets][1][:pages][1])
        foreach(pn[:nets]) do net
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

