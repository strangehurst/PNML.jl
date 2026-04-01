module PNet
__precompile__(true)

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage

import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import XMLDict
import Multisets: Multisets, Multiset

#using PNML

import PNML
import PNML: PnmlModel, PnmlNet
import PNML: initial_markings, initial_marking, enabled, PnmlMultiset, pid
import PNML: metagraph, pnmlmodel
import PNML: ToolParser, LabelParser
import PNML: input_matrix, output_matrix
import PNML: nettype, rates
import PNML: pntd

using PNML.PnmlTypes
using PNML.Labels
using PNML.Sorts
using PNML.PnmlGraphics
using PNML.Declarations

export AbstractPetriNet, SimpleNet
export input_matrix, output_matrix, transition_function, pnmlnet
export labeled_transitions, counted_transitions

include("petrinet.jl")
include("transition_function.jl")
include("firing_rule.jl")

end # module PNet
