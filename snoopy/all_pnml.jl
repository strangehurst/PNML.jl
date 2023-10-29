#julia -e 'include("all_pnml.jl"); testpn()'
#julia -e 'include("all_pnml.jl"); testpn(dir="MCC")'
#julia -e 'include("all_pnml.jl"); testpn(topdir="/home/jeff/Projects/Resources/PetriNet/ePNK", dir="pnml-examples")'
#julia -t1 --project=.snoopy  -e 'include("all_pnml.jl"); testpn("")' 2>&1 | tee  /tmp/testpn.txt
using PNML
using DataFrames, DataFramesMeta, Dates, CSV, Graphs, MetaGraphsNext

pnml_files(files) = filter(files) do f
    isfile(f) && success(run(Cmd(`grep -qF "<pnml" $f`, ignorestatus=true)))
end

outputlog = "runlog.txt"

function testpn(dir::AbstractString = "examples";
                topdir = "/home/jeff/Projects/Resources/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")
    testpn(tuple(dir); topdir, outdir)
end

function testpn(dirs = ("examples",);
                topdir = "/home/jeff/Projects/Resources/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")

    outdir = joinpath(outdir, Dates.format(now(), dateformat"yyyymmddHHMM"))
    mkpath(outdir)
    @show outdir

    df = DataFrame()
    for srcdir in dirs #! Loop over input directories

        in_dir  = joinpath(topdir, srcdir)
        cd(in_dir) do
            @show pwd()
            for (root, dirs, files) in walkdir(".")
                flist = map(f -> joinpath(root, f), filter(endswith(r"pnml|xml"), files))
                pnmls = filter(f -> success(run( Cmd(`grep -qF "<pnml xmlns" $f`, ignorestatus=true))), flist)
                for file in pnmls
                    per_file!(df, outdir, file)
                    #TODO grep
                end
            end
            println()
        end
    end

    expfile = joinpath(outdir, "exceptions.txt")
    cd(outdir) do
        x =  read(`find . -type f -exec grep -nHA3 'CAUGHT' \{\} \;`, String)
        write(expfile, x)
    end
    sort!(df, [:time])
    write(joinpath(outdir, "DataFrame.txt"), repr(df))
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
end

function per_file!(df, outdir::AbstractString, filename::AbstractString)
    outfile = joinpath(outdir, (first ∘ splitext)(filename))
    #@show filename

    isfile(outfile) && println("Warning overwriting $outfile")
    mkpath(dirname(outfile)) # Create output directory.

    println(filename, " input size = ", filesize(filename)) # Display path to file and size.
    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
        try
            println(stat(filename))
            println()
            stats = @timed parse_file(filename)
            push!(df, (file=filename, fsize=filesize(filename),
                       time=stats.time, bytes=stats.bytes, gctime=stats.gctime))

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

        catch e
            println("\nCAUGHT EXCEPTION: ", sprint(showerror, e, Base.catch_backtrace()))
            if e isa InterruptException
                rethrow()
            end
        end # try
    end   # redirect
end
