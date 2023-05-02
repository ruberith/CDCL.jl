"""
Create an expression for defining a variable and adding it to the model.

Return the created `Expr`.
"""
function create_variable(model, name, priority)
    return quote
        local MODEL::Model = $(esc(model))
        local NAME::String = $(string(name))
        local PRIORITY::Int = $(esc(priority))
        # Define the variable and add it to the model.
        local var::Variable = Variable()
        var.priority = PRIORITY
        push!(MODEL.variables, NAME => var)
        var
    end
end

"""
Usage:

    @variable <model> <name>

Define a variable with default priority (0) and add it to the model.

Return the defined `Variable`.
"""
macro variable(model, name)
    return create_variable(model, name, :(0))
end

"""
Usage:

    @variable <model> <name> <priority>

Define a variable with custom priority and add it to the model.

Return the defined `Variable`.
"""
macro variable(model, name, priority)
    return create_variable(model, name, priority)
end

"""
Usage:

    @clause <model> <name> [ (¬|!|ε)<variable> ... ]

Define a clause and add it to the model.

Return the defined `Clause`.
"""
macro clause(model, name, literals)
    return quote
        local MODEL::Model = $(esc(model))
        local NAME::String = $(string(name))
        local LITERALS::Vector{SubString{String}} = $(split(string(literals)[2:end-1]))
        # Define the clause.
        local clause::Clause = Clause()
        local i::Int = 1
        for literal in LITERALS
            # Parse name and type of the literal.
            local var::String
            local type::Bool
            if literal[1] == '!'
                var = literal[2:end]
                type = false
            elseif literal[1] == '¬'
                var = literal[3:end]
                type = false
            else
                var = literal
                type = true
            end
            # Add the literal to the clause.
            push!(clause.literals, var => type)
            # Add the clause to the watch list for the first two literals.
            if i <= 2
                clause.watch[i] = var
                push!(MODEL.variables[var].watch, NAME => type)
            end
            i += 1
        end
        # Add the clause to the model.
        push!(MODEL.clauses, NAME => clause)
        clause
    end
end
