# Preference scheme inspired by Cthuhlu.jl
using Preferences: Preferences, @load_preference, @set_preferences!

"""
    save_config!(config::PnmlConfig=CONFIG)

Save a configuration to your `LocalPreferences.toml` file using Preferences.jl.
The saved preferences will be automatically loaded next time you do `using PNML`

## Examples
```julia
julia> using PNML

julia> PNML.CONFIG[].verbose = true;

julia> PNML.CONFIG[].warn_on_unclaimed = true;     # Customize some defaults

julia> PNML.save_config!(PNML.CONFIG[]); # Will be automatically read next time you `using PNML`
```
"""
function save_config!(config::PnmlConfig = CONFIG[])
    @set_preferences!(
        "indent_width" => config.indent_width,
        "text_element_optional" => config.text_element_optional,
        "verbose" => config.verbose,
        "warn_on_namespace" => config.warn_on_namespace,
        "warn_on_fixup" => config.warn_on_fixup,
        "warn_on_unclaimed" => config.warn_on_unclaimed,
        "warn_on_unimplemented" => config.warn_on_unimplemented,

        "base_path" => config.base_path,
        "log_path" => config.log_path,
        "log_level" => config.log_level,
        "log_to_file" => config.log_to_file,
        "log_date_format" => config.log_date_format,
        )
end

function read_config!(config::PnmlConfig)
    config.indent_width = @load_preference("indent_width", config.indent_width)
    config.text_element_optional = @load_preference("text_element_optional", config.text_element_optional)
    config.verbose = @load_preference("verbose", config.verbose)
    config.warn_on_namespace = @load_preference("warn_on_namespace", config.warn_on_namespace)
    config.warn_on_fixup = @load_preference("warn_on_fixup", config.warn_on_fixup)
    config.warn_on_unclaimed = @load_preference("warn_on_unclaimed", config.warn_on_unclaimed)
    config.warn_on_unimplemented = @load_preference("warn_on_unimplemented", config.warn_on_unimplemented)

    config.base_path = @load_preference("base_path", config.base_path)
    config.log_path = @load_preference("log_path",config.log_path)
    config.log_level = @load_preference("log_level",config.log_level)
    config.log_to_file, = @load_preference("log_to_file",config.log_to_file)
    config.log_date_format = @load_preference("log_date_format",config.log_date_format)
end

function Base.show(io::IO, config::PnmlConfig)
    println(io, "indent_width          = ", config.indent_width)
    println(io, "text_element_optional = ", config.text_element_optional)
    println(io, "verbose               = ", config.verbose)
    println(io, "warn_on_namespace     = ", config.warn_on_namespace)
    println(io, "warn_on_fixup         = ", config.warn_on_fixup)
    println(io, "warn_on_unclaimed     = ", config.warn_on_unclaimed)
    println(io, "warn_on_unimplemented = ", config.warn_on_unimplemented)
    println(io, "base_path             = ", config.base_path)
    println(io, "log_path              = ", config.log_path)
    println(io, "log_level             = ", config.log_level)
    println(io, "log_to_file           = ", config.log_to_file)
    println(io, "log_date_format       = ", config.log_date_format)
end
