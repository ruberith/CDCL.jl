"""
Check whether the given clause is asserting, i.e. contains at most one literal from the current decision level.

Return `true` if the clause is asserting and `false` otherwise.
"""
function is_asserting(model::Model, clause::Clause, current_decision_level::Int)::Bool
    local count::Int = 0
    for name in keys(clause.literals)
        if model.variables[name].decision_level == current_decision_level
            count += 1
        end
        if count >= 2
            return false
        end
    end
    return true
end

"""
Resolve two clauses over a variable.

Return the resolvent `Clause`.
"""
function resolve(variable::String, clause1::Clause, clause2::Clause)::Clause
    local resolvent::Dict{String,Bool} = merge(clause1.literals, clause2.literals)
    filter!(literal -> literal.first != variable, resolvent)
    return Clause(literals=resolvent)
end

"""
Perform Conflict-Driven Clause Learning (CDCL).

Return `true` if the conflict is resolved by learning the asserting clause and `false` if the conflict is at decision level 0, i.e. unresolvable.
"""
function learn!(model::Model)::Bool
    local current::String = model.trail
    local current_decision_level::Int = model.variables[current].decision_level
    if current_decision_level == 0
        # The conflict is at decision level 0, i.e. unresolvable.
        return false
    end
    local clause::Clause = model.clauses[model.conflict]
    local involved_variables::Set{String} = Set{String}()
    for name in keys(clause.literals)
        push!(involved_variables, name)
    end
    # Make the conflicting clause asserting via resolution.
    while !is_asserting(model, clause, current_decision_level)
        # Resolve the clause over the last assigned variable with its antecedent.
        local antecedent::Clause = model.clauses[model.variables[current].antecedent]
        for name in keys(antecedent.literals)
            push!(involved_variables, name)
        end
        clause = resolve(current, clause, antecedent)
        current = model.variables[current].predecessor
    end
    # Increment the VSIDS conflict counter of the involved variables.
    for name in involved_variables
        model.variables[name].conflicts += model.vsids_increment
    end
    # Increase the VSIDS increment.
    model.vsids_increment += model.vsids_increase
    # Update the VSIDS period progress.
    model.vsids_progress += 1
    # Periodically, decay both VSIDS increment and conflict counter of all variables.
    if model.vsids_progress == model.vsids_period
        for variable in values(model.variables)
            variable.conflicts *= model.vsids_decay
        end
        model.vsids_increment *= model.vsids_decay
        model.vsids_progress = 0
    end
    # Learned asserting clauses are named using Roman numerals.
    model.num_learned += 1
    local asserting::String = "c$(RomanNumeral(model.num_learned))"
    local i::Int = 1
    local new_decision_level::Int = 0
    for name in keys(clause.literals)
        # Find the second-highest decision level.
        local decision_level::Int = model.variables[name].decision_level
        if decision_level > new_decision_level && decision_level < current_decision_level
            new_decision_level = decision_level
        end
        # Find the member variable from the current decision level.
        if decision_level == current_decision_level
            current = name
        end
        # Add the clause to the watch list for the first two literals.
        if i <= 2
            clause.watch[i] = name
            push!(model.variables[name].watch, asserting => clause.literals[name])
        end
        i += 1
    end
    # Backtrack to the second-highest decision level.
    while !isnothing(model.trail) && model.variables[model.trail].decision_level > new_decision_level
        local var::Variable = model.variables[model.trail]
        model.trail = var.predecessor
        var.assignment = nothing
        var.decision_level = nothing
        var.antecedent = nothing
        var.predecessor = nothing
    end
    # Add the asserting clause to the model.
    push!(model.clauses, asserting => clause)
    # The asserting clause is now unit, so assign the implied literal.
    local var::Variable = model.variables[current]
    var.assignment = clause.literals[current]
    var.decision_level = new_decision_level
    var.antecedent = asserting
    var.predecessor = model.trail
    model.trail = current
    @event output_learn(var.antecedent, current => var)
    # The conflict is now resolved.
    model.conflict = nothing
    return true
end
