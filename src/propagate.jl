"""
Perform Boolean Constraint Propagation (BCP).

Return `true` if the propagation is concluded without conflicts and `false` otherwise.
"""
function propagate!(model::Model)::Bool
    local assignments::Queue{String} = Queue{String}()
    if isnothing(model.trail)
        # Check for empty and single-literal clauses.
        for (name, clause) in model.clauses
            if length(clause.literals) == 0
                # The formula contains an empty clause, so it is unsatisfiable.
                model.conflict = name
                @event output_conflict(model.conflict, nothing)
                return false
            end
            if length(clause.literals) == 1
                local watched::String = clause.watch[1]
                local var::Variable = model.variables[watched]
                if isnothing(var.assignment)
                    # Assign and propagate the literal implied by the single-literal clause.
                    var.assignment = clause.literals[watched]
                    var.decision_level = 0
                    var.antecedent = name
                    var.predecessor = model.trail
                    model.trail = watched
                    @event output_propagate(var.antecedent, watched => var)
                    enqueue!(assignments, watched)
                else
                    if var.assignment != clause.literals[watched]
                        # The formula contains contradictory single-literal clauses, so it is unsatisfiable.
                        model.conflict = name
                        @event output_conflict(model.conflict, watched => var)
                        return false
                    end
                end
            end
        end
    else
        # Propagate the last assignment.
        enqueue!(assignments, model.trail)
    end
    # Iteratively propagate assignments.
    while !isempty(assignments)
        local assigned::String = dequeue!(assignments)
        # Check the watch list of the assigned variable for the opposite of the assignment.
        for (name, type) in model.variables[assigned].watch
            if type != model.variables[assigned].assignment
                local clause::Clause = model.clauses[name]
                local other::StringOrNothing = (assigned == clause.watch[1]) ? clause.watch[2] : clause.watch[1]
                if isnothing(other)
                    # The clause contains a single literal of the opposite type, so it is conflicting.
                    model.conflict = name
                    @event output_conflict(model.conflict, assigned => model.variables[assigned])
                    return false
                end
                if !isnothing(model.variables[other].assignment) && model.variables[other].assignment == clause.literals[other]
                    # The clause contains a true literal, so it is satisfied.
                    continue
                end
                # Try to find a new non-false literal to watch.
                local found_new_literal::Bool = false
                for member in keys(clause.literals)
                    if member == assigned || member == other
                        continue
                    end
                    if isnothing(model.variables[member].assignment) || model.variables[member].assignment == clause.literals[member]
                        # Replace the watched literal.
                        clause.watch[(assigned == clause.watch[1]) ? 1 : 2] = member
                        delete!(model.variables[assigned].watch, name)
                        push!(model.variables[member].watch, name => clause.literals[member])
                        found_new_literal = true
                        break
                    end
                end
                if !found_new_literal
                    local var::Variable = model.variables[other]
                    if isnothing(var.assignment)
                        # The clause is unit, so assign and propagate the implied literal.
                        var.assignment = clause.literals[other]
                        var.decision_level = model.variables[model.trail].decision_level
                        var.antecedent = name
                        var.predecessor = model.trail
                        model.trail = other
                        @event output_propagate(var.antecedent, other => var)
                        enqueue!(assignments, other)
                    else
                        # The clause contains only false literals, so it is conflicting.
                        model.conflict = name
                        @event output_conflict(model.conflict, other => var)
                        return false
                    end
                end
            end
        end
    end
    return true
end
