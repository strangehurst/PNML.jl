# Start with a copy of Petri.jl examples/lotka-volterra.jl.
#
using PNML: PNML, SimpleNet, place_idset, transition_function, initial_markings, rates
using Petri: Petri, Model, Graph, ODEProblem
using LabelledArrays
using Plots: Plots
using OrdinaryDiffEq: OrdinaryDiffEq, Tsit5


"""
PNML model for the original example below. Note that the type is "continuous"!
"""
 str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
        <page id="page0">
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
            <arc id="a1" source="rabbits"   target="birth">     <inscription><text>1</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits">   <inscription><text>2</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves">    <inscription><text>2</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death">     <inscription><text>1</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
"""

net = PNML.SimpleNet(str)

# **Step 1:** Define the states and transitions of the Petri Net
#
# Here we have 2 states, wolves and rabbits, and transitions to
# model predation between the two species in the system

S = PNML.place_idset(net) # [:rabbits, :wolves]
Δ = PNML.transition_function(net)
# keys are transition ids,
# values are tuple of input, output vectors
#       with keys of place id and values of inscription value .
#LVector(
#       birth=(LVector(rabbits=1), LVector(rabbits=2)),
#       predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
#       death=(LVector(wolves=1), LVector()),
#     )

# AlgebraicJulia wants LabelledPetriNet constructed with
# with Varargs pairs of transition_name=>((input_states)=>(output_states))
# example LabelledPetriNet([:S, :I, :R], :inf=>((:S,:I)=>(:I,:I)), :rec=>(:I=>:R))

lotka = Petri.Model(S, Δ)

display(Petri.Graph(lotka))


# **Step 2:** Define the parameters and transition rates
#
# Once a model is defined, we can define out initial parameters `u0`, a time
# span `tspan`, and the transition rates of the interactions `β`

u0 = PNML.initial_markings(net) #LVector(wolves=10.0, rabbits=100.0)
tspan = (0.0,100.0)
β = PNML.rates(net) #LVector(birth=.3, predation=.015, death=.7); # transition rate

# **Step 3:** Generate a solver and solve
#
# Finally we can generate a solver and solve the simulation

# AlgebraicPetri.ODEProblem uses a AlgebraicPetri.AbstractetriNet a C-Set
prob = Petri.ODEProblem(lotka, u0, tspan, β) # transform using Petri.vectorfield(m)
sol = OrdinaryDiffEq.solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

display(Plots.plot(sol))
