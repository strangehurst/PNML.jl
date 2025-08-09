using SciMLLogging
using Logging

# function add_datetime_logger(logger)
#     return TransformerLogger(logger) do log
#         merge(log, (; message = "[$(Dates.now())]-#$(Threads.threadid()): $(log.message)"))
#     end
# end

"Return open file IO object."
function logfile(config)
    mktemp(mkpath(join([tempdir(), config.base_path, config.log_path], "/")); cleanup=false)[2]
end

function logger_for_pnml(file::IOStream, minlevel = Logging.Warn)
    LoggingExtras.MinLevelLogger(
        LoggingExtras.TeeLogger(
            LoggingExtras.MinLevelLogger(ConsoleLogger(stdout), Logging.Info),
            LoggingExtras.FileLogger(file)),
        minlevel)
end

# maybe_with_logger(f, logger) = logger === nothing ? f() : Logging.with_logger(f, logger)

# function default_logger(logger)
#     Logging.min_enabled_level(logger) ≤ ProgressLogging.ProgressLevel && return nothing

#     if Sys.iswindows() || (isdefined(Main, :IJulia) && Main.IJulia.inited)
#         progresslogger = ConsoleProgressMonitor.ProgressLogger()
#     else
#         progresslogger = TerminalLoggers.TerminalLogger()
#     end

#     logger1 = LoggingExtras.EarlyFilteredLogger(progresslogger) do log
#         log.level == ProgressLogging.ProgressLevel
#     end
#     logger2 = LoggingExtras.EarlyFilteredLogger(logger) do log
#         log.level != ProgressLogging.ProgressLevel
#     end

#     LoggingExtras.TeeLogger(logger1, logger2)
# end
