#julia -e 'include("all_pnml.jl"); testpn()'
#julia -e 'include("all_pnml.jl"); testpn(dir="MCC")'
#julia -e 'include("all_pnml.jl"); testpn(topdir="/home/jeff/Projects/Resources/PetriNet/ePNK", dir="pnml-examples")'
#julia -t1 --project=.snoopy  -e 'include("all_pnml.jl"); testpn("")' 2>&1 | tee  /tmp/testpn.txt
using PNML
using DataFrames, DataFramesMeta, Dates, CSV, Graphs, MetaGraphsNext
using LoggingExtras


pnml_files(files) = filter(files) do f
    isfile(f) && success(run(Cmd(`grep -qF "<pnml" $f`, ignorestatus=true)))
end

function testpn(dir::AbstractString = "examples";
                topdir = "/home/jeff/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")
    testpn(tuple(dir); topdir, outdir)
end

function testpn(dirs = ("examples",);
                topdir = "/home/jeff/Projects/Resources/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")

    outdir = joinpath(outdir, Dates.format(now(), dateformat"yyyymmddHHMM"))
    mkpath(outdir)

    consolelogger = ConsoleLogger(stdout, Logging.Debug)
    outputlog = joinpath(outdir, "testrun.log")
    filelogger = FileLogger(outputlog)
    demux_logger = TeeLogger(consolelogger, MinLevelLogger(filelogger, Logging.Debug))
    global_logger(demux_logger)

    @show topdir dirs outdir outputlog
    df = DataFrame()
    start_time = now()
    @info "start time" start_time
    @time for srcdir in dirs #! Loop over input directories
        in_dir  = joinpath(topdir, srcdir)
        cd(in_dir) do
            println("Input Directory ", pwd())
            for (root, dirs, files) in walkdir(".")
                #map(println, Iterators.map(f -> joinpath(root, f), dirs))
                flist = map(f -> joinpath(root, f), filter(endswith(r"pnml|xml"), files))
                #map(println, flist)
                pnmls = filter(f -> success(run( Cmd(`grep -qF "<pnml xmlns" "$f"`, ignorestatus=true))), flist)
                for file in pnmls
                    per_file!(df, outdir, file)
                end
            end
            println()
        end
    end

    # Exception Summary Report
    xfile = open(joinpath(outdir, "exceptions.txt"), "w")
    cd(outdir) do
        for (root, dirs, files) in walkdir(".")
            flist = map(f -> joinpath(root, f), files)
            for f in filter(f -> success(run(Cmd(`grep -q "^CAUGHT EXCEPTION" $f`, ignorestatus=true))), flist)
                x = read(`grep -nHP -A3 '^CAUGHT' $f`, String)
                write(xfile, x, "\n")
            end
        end
    end # cd
    close(xfile)

    sort!(df, [:time])
    write(joinpath(outdir, "DataFrame.txt"), repr(df))
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
    println("finish_time = ", now(), ", elapsed time = ", (now() - start_time))
end

#-----------------------------------
# `filename` is relative to the cwd. `outdir` is absolute or relative
function per_file!(df, outdir::AbstractString, filename::AbstractString)
    outfile = joinpath(outdir, string(filename, ".txt")) #(first ∘ splitext)(filename))
    #@show filename

    isfile(outfile) && println("Warning overwriting $outfile")
    mkpath(dirname(outfile)) # Create output directory.
    file_start = now()
    @info "File $filename at $(Time(file_start)) size = $(filesize(filename))" # Display path to file and size.

    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
        try
            println(stat(filename), " at ", Time(file_start))
            println()
            stats = @timed parse_file(filename)
            push!(df, (file=filename, fsize=filesize(filename),
                       time=stats.time, bytes=stats.bytes, gctime=stats.gctime))

            # Display PnmlModel as a test of parsing, creation and show().
            println(stats.value)
            println("took ", stats.time, " memory bytes :", stats.bytes)

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
            bt = Base.catch_backtrace()

            println("\n\nCAUGHT EXCEPTION:", sprint(showerror, e, bt)) # full backtrace to file
            @info "CAUGHT EXCEPTION: $(sprint(showerror,e))"
            #! Ignore first ^C, it serves to end prossing of a single file.
            #! The "second" (is there a window of opurtunity?) should end the loop processing files.
            # e isa InterruptException && rethrow()
            # end
        end # try
    end   # redirect
    # print exceptions
    run(Cmd(`grep "^CAUGHT EXCEPTION" $outfile`, ignorestatus=true))
end
