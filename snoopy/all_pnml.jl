#julia -e 'include("all_pnml.jl"); testpn()'
#julia -e 'include("all_pnml.jl"); testpn(dir="MCC")'
#julia -e 'include("all_pnml.jl"); testpn(topdir="/home/jeff/Projects/Resources/PetriNet/ePNK", dir="pnml-examples")'

using PNML
using DataFrames, DataFramesMeta, Dates, CSV, Graphs, MetaGraphsNext

function testpn(; topdir = "/home/jeff/Projects/Resources/PetriNet/PNML", dir = "examples",
                  outdir = "/home/jeff/Jules/testpmnl")
    df = DataFrame() # Collects data from tests.
    indir  = joinpath(topdir, dir)
    subd = Dates.format(now(), dateformat"yyyymmddHHMM")
    outdir = joinpath(outdir, subd)
    mkpath(outdir)
    @show indir outdir
    cd(indir) do
        for (root, dirs, files) in walkdir(".")
            for file in filter(endswith(".pnml"), files)
                f = lstrip(joinpath(root, file), ['.', '/'])
                println(f, " size = ", filesize(f)) # Display path to file and size.
                try
                    # Collect per-file output.
                    #outfile = joinpath(outdir, (first ∘ splitext ∘ basename)(f))
                    outfile = joinpath(outdir, (first ∘ splitext)(f))
                    mkpath(dirname(outfile)) # Create output directory.
                    isfile(outfile) && println("Warning overwriting $outfile")
                    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
                        println(f)
                        println()
                        stats = @timed parse_file(f)
                        push!(df, (file=f, fsize=filesize(f), time=stats.time, bytes=stats.bytes, gctime=stats.gctime))
                        # Display PnmlModel as a test of parsing, creation and show().
                        println(stats.value)
                        println()
                        # Petri Net & Graph
                        @showtime anet = PNML.SimpleNet(stats.value)
                        @showtime mg = PNML.metagraph(anet)
                        @showtime Graphs.is_bipartite(mg)
                        @showtime Graphs.ne(mg)
                        @showtime Graphs.nv(mg)
                        @showtime MetaGraphsNext.labels(mg) #|> collect
                        @showtime MetaGraphsNext.edge_labels(mg) #|> collect
                        println("-----")
                        #C = PNML.incidence_matrix(anet)
                        #@showtime C  = PNML.incidence_matrix(anet)
                        @showtime m₀ = PNML.initial_markings(anet)
                        #@showtime e  = PNML.enabled(anet, m₀)
                        println("-----")
                    end
                catch e
                    if e isa PNML.PnmlException
                        @warn " failed: $e"
                    elseif e isa InterruptException
                        return
                    else
                        sprint(showerror, e)
                    end
                end
            end
        end
    end

    sort!(df, [:time])
    write(joinpath(outdir, "DataFrame.txt"), repr(df))
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
end
