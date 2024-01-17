# From Cthuhlu.jl

"""
    save_config!(config::PnmlConfig=CONFIG)

Save a configuration to your `LocalPreferences.toml` file using Preferences.jl. The saved preferences will be automatically loaded next time you `using PNML`

## Examples
```julia
julia> using PNML

julia> PNML.CONFIG.verbose = true;

julia> PNML.CONFIG.warn_on_unclaimed = true;     # Customize some defaults

julia> PNML.save_config!(PNML.CONFIG); # Will be automatically read next time you `using PNML`
```
"""
function save_config!(config::PnmlConfig = CONFIG)
    @set_preferences!(
        "indent_width" => config.indent_width,
        "lock_registry" => config.lock_registry,
        "text_element_optional" => config.text_element_optional,
        "verbose" => config.verbose,
        "warn_on_namespace" => config.warn_on_namespace,
        "warn_on_fixup" => config.warn_on_fixup,
        "warn_on_unclaimed" => config.warn_on_unclaimed,
        )
end

function read_config!(config::PnmlConfig)
    config.indent_width = @load_preference("indent_width", config.indent_width)
    config.lock_registry = @load_preference("lock_registry", config.lock_registry)
    config.text_element_optional = @load_preference("text_element_optional", config.text_element_optional)
    config.verbose = @load_preference("verbose", config.verbose)
    config.warn_on_namespace = @load_preference("warn_on_namespace", config.warn_on_namespace)
    config.warn_on_fixup = @load_preference("warn_on_fixup", config.warn_on_fixup)
    config.warn_on_unclaimed = @load_preference("warn_on_fixup", config.warn_on_unclaimed)
end

function Base.show(io::IO, config::PnmlConfig)
    println("indent_width          = ", config.indent_width)
    println("lock_registry         = ", config.lock_registry)
    println("text_element_optional = ", config.text_element_optional)
    println("verbose               = ", config.verbose)
    println("warn_on_namespace     = ", config.warn_on_namespace)
    println("warn_on_fixup         = ", config.warn_on_fixup)
    println("warn_on_unclaimed     = ", config.warn_on_unclaimed)
end
