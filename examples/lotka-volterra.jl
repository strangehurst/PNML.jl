# Start with a copy of Petri.jl examples/lotka-volterra.jl.
#
using PNML
using Petri
using LabelledArrays
using Plots
using OrdinaryDiffEq


 str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="stochastic">
        <page id="page0">
            <place id="wolves"> <initialMarking> <text>2</text> </initialMarking> </place>
            <place id="rabbits"> <initialMarking> <text>1</text> </initialMarking> </place>
            <transition id ="birth"> <condition> <text>0.1</text> </condition> </transition>
            <transition id ="death"> <condition> <text>0.1</text> </condition> </transition>
            <transition id ="predation"> <condition> <text>0.1</text> </condition> </transition>
            <arc id="a1" source="rabbits" target="birth"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a2" source="birth" target="rabbits"> <inscription><text>2</text> </inscription> </arc>
            <arc id="a3" source="wolves" target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a4" source="rabbits" target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves"> <inscription><text>2</text> </inscription> </arc>
            <arc id="a6" source="wolves" target="death"> <inscription><text>1</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
""" 
 
net = PNML.SimpleNet(str)


# **Step 1:** Define the states and transitions of the Petri Net
# 
# Here we have 2 states, wolves and rabbits, and transitions to
# model predation between the two species in the system

S = PNML.place_ids(net) # [:rabbits, :wolves]
Δ = PNML.transition_function(net)
# keys are transition ids
# values are input, output vectors of "tuples" place id -> inscription
#LVector(
#       birth=(LVector(rabbits=1), LVector(rabbits=2)),
#       predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
#       death=(LVector(wolves=1), LVector()),
#     )
lotka = Petri.Model(S, Δ)

display(Graph(lotka))


# **Step 2:** Define the parameters and transition rates
#
# Once a model is defined, we can define out initial parameters `u0`, a time
# span `tspan`, and the transition rates of the interactions `β`

u0 = PNML.initialMarking(net) #LVector(wolves=10.0, rabbits=100.0) # initialMarking
tspan = (0.0,100.0)
β = PNML.conditions(net) #LVector(birth=.3, predation=.015, death=.7); # transition condition

# **Step 3:** Generate a solver and solve
#
# Finally we can generate a solver and solve the simulation

prob = ODEProblem(lotka, u0, tspan, β) # transform PetriNet problem using vectorfield(m)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)

plot(sol)

