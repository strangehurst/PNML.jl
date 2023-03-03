# From Cthuhlu.jl

"""
```julia
save_config!(config::PnmlConfig=CONFIG)
```
Save a PNML.jl configuration `config` (by default, `PNML`) to your
`LocalPreferences.toml` file using Preferences.jl.

The saved preferences will be automatically loaded next time you `using PNML`

## Examples
```julia
julia> using PNML

julia> PNML.CONFIG.verbose = true
true

julia> PNML.CONFIG.warn_on_unclaimed = true     # Customize some defaults
true

julia> PNML.save_config!(PNML.CONFIG) # Will be automatically read next time you `using PNML`
```
"""
function save_config!(config::PnmlConfig=CONFIG)
    @set_preferences!(
        "indent_width" => config.indent_width,
        "warn_on_namespace" => config.warn_on_namespace,
        "text_element_optional" => config.text_element_optional,
        "warn_on_fixup" => config.warn_on_fixup,
        "warn_on_unclaimed" => config.warn_on_unclaimed,
        "verbose" => config.verbose,
        )
end

function read_config!(config::PnmlConfig)
    config.indent_width = @load_preference("indent_width", config.indent_width)
    config.warn_on_namespace = @load_preference("", config.warn_on_namespace)
    config.text_element_optional = @load_preference("text_element_optional", config.text_element_optional)
    config.warn_on_fixup = @load_preference("warn_on_fixup", config.warn_on_fixup)
    config.warn_on_unclaimed = @load_preference("warn_on_fixup", config.warn_on_unclaimed)
    config.verbose = @load_preference("verbose", config.verbose)
end
