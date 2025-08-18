using SciMLLogging: SciMLLogging, Verbosity, @SciMLMessage
using Logging
using LoggingExtras

using PNML


# Define option groups
mutable struct SolverOptions
    iterations::Verbosity.Type
    convergence::Verbosity.Type

    function SolverOptions(;
            iterations = Verbosity.Info(),
            convergence = Verbosity.Warn()
    )
        new(iterations, convergence)
    end
end

mutable struct PerformanceOptions
    timing::Verbosity.Type
    memory::Verbosity.Type

    function PerformanceOptions(;
            timing = Verbosity.None(),
            memory = Verbosity.None()
    )
        new(timing, memory)
    end
end

mutable struct PnmlVerbosityOptions
    information::Verbosity.Type
    warning::Verbosity.Type
    error::Verbosity.Type

    function PnmlVerbosityOptions(;
            warning = Verbosity.Warn(),
            error = Verbosity.Info(),
            information = Verbosity.Info(),
    )
        new(information, warning, error)
    end
end

# Main verbosity struct
struct PnmlVerbosity{T} <: SciMLLogging.AbstractVerbositySpecifier{T}
    options::PnmlVerbosityOptions
    solver::SolverOptions
    performance::PerformanceOptions

    function PnmlVerbosity{T}(;
            options = PnmlVerbosityOptions(),
            solver = SolverOptions(),
            performance = PerformanceOptions()
    ) where {T}
        new{T}(options, solver, performance)
    end
end

# Constructor with enable/disable parameter
PnmlVerbosity(; enable = true, kwargs...) = PnmlVerbosity{enable}(; kwargs...)
verbose = PnmlVerbosity{true}() # Create enabled verbosity
silent = PnmlVerbosity{false}() # Create disabled verbosity

"Return file path string after creating intermediate directories."
function logfile(config, filename)
    logname = joinpath(tempdir(), config.base_path, config.log_path, filename)
    mkpath(dirname(logname))
    return logname
    #mktemp(path; cleanup=false)[2]
end
function logstream(path; kwds...)
    open(path, "a")
end
# Create a logger
logger_for_pnml = SciMLLogging.SciMLLogger(
    info_repl = true,     # Show info in REPL
    warn_repl = true,     # Show warnings in REPL
    error_repl = true,    # Show errors in REPL
    info_file = logstream(logfile(CONFIG[], "infos.log")),  # Also log to file
    warn_file = logstream(logfile(CONFIG[], "warnings.log")), # Also log to file
    error_file = logstream(logfile(CONFIG[], "errors.log")), # Also log warnings to file
)
