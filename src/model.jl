"""
    Variable

Composite type which contains all variable-specific information for the solver.
"""
Base.@kwdef mutable struct Variable
    # watch list: name of the watched clause => literal type
    watch::Dict{String,Bool} = Dict{String,Bool}()
    # current assignment
    assignment::BoolOrNothing = nothing
    # decision level the assignment occurred on
    decision_level::IntOrNothing = nothing
    # antecedent clause implying the assignment
    antecedent::StringOrNothing = nothing
    # name of the variable preceding in the assignment trail
    predecessor::StringOrNothing = nothing
    # primary priority: VSIDS conflict counter
    conflicts::Int = 0
    # secondary priority: static value
    priority::Int = 0
end

"""
    Clause

Composite type which contains all clause-specific information for the solver.
"""
Base.@kwdef struct Clause
    # literals: variable name => literal type
    literals::Dict{String,Bool} = Dict{String,Bool}()
    # names of the variables having the clause on their watch lists
    watch::Vector{StringOrNothing} = [nothing, nothing]
end

"""
    Model

Composite type which contains all model-specific information for the solver.

Create a model using the constructor `Model()`.

The following model parameters / fields may be set:
- `decision::Bool` – assignment used when making a heuristics-based decision for a variable
- `vsids_increment::Int` – increment of the VSIDS conflict counter for variables involved in a conflict
- `vsids_increase::Int` – increase of the VSIDS increment after each conflict
- `vsids_period::Int` – number of conflicts per VSIDS period
- `vsids_decay::Float64` – multiplier for both VSIDS increment and conflict counters at the end of a period
- `output::BoolOrNothing` – output events and assignments (`true`), only model and solution (`false`), or `nothing`

Add variables using the macro `@variable <model> <name> (<priority>|ε)`.

Add clauses using the macro `@clause <model> <name> [ (¬|!|ε)<variable> ... ]`.

Solve the model with the function `solve!(model::Model)`.

If the formula is satisfiable, a satisfying assignment can be obtained from the model field `variables` by accessing the field `assignment` of each `Variable`.

Note that a model should not be reused.
"""
Base.@kwdef mutable struct Model
    # variables: name => variable
    variables::Dict{String,Variable} = Dict{String,Variable}()
    # clauses: name => clause
    clauses::Dict{String,Clause} = Dict{String,Clause}()
    # assignment used when making a heuristics-based decision for a variable
    decision::Bool = false
    # increment of the VSIDS conflict counter for variables involved in a conflict
    vsids_increment::Int = 1
    # increase of the VSIDS increment after each conflict
    vsids_increase::Int = 1
    # number of conflicts per VSIDS period
    vsids_period::Int = 10
    # multiplier for both VSIDS increment and conflict counters at the end of a period
    vsids_decay::Float64 = 0.5
    # output events and assignments (true), only model and solution (false), or nothing
    output::BoolOrNothing = true
    # number of conflicts recorded in the current VSIDS period
    vsids_progress::Int = 0
    # name of the last variable in the assignment trail
    trail::StringOrNothing = nothing
    # name of the current conflicting clause
    conflict::StringOrNothing = nothing
    # number of learned asserting clauses
    num_learned::Int = 0
end
