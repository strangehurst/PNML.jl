"""
Infrastructure implementing the core of the Petri Net Modeling Language.
Upon this base is built mechanisms for Place-Transition, High-Level Petri Nets,
and extensions.

$(DocStringExtensions.IMPORTS)
$(DocStringExtensions.EXPORTS)

"""
module PnmlCore

# Parse
export @xml_str,
    xmlroot,
    parse_str,
    parse_file,
    parse_pnml

# Exceptions
export PnmlException,
    MissingIDException,
    MalformedException
end # module PnmlCore
