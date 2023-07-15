function value_function_model(prob::PricingProblem; silent=false, threads=nothing, heuristic=true)
    model = base_model(prob; silent, threads)
    heuristic && add_heuristic_provider!(model)
    add_value_function_callback!(model; threads)
    return model
end

function add_value_function_callback!(model; threads=nothing)
    prob = model[:prob]
    t, f = model[:t], model[:f]
    c, i1 = base_costs(prob), collect(tolled(prob))

    model[:follower] = follower_model(prob; silent=true, threads)
    model[:vf_x] = Set{Vector{Int}}()
    model[:callback_time] = 0.
    model[:callback_calls] = 0

    provider = haskey(model, :heur_provider) ? model[:heur_provider] : nothing

    function lazy_callback(cb_data)
        status = callback_node_status(cb_data, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return
        end

        model[:callback_time] += @elapsed begin
            # Solve the follower's problem with the given toll
            x̂, t̂, follower_obj, current_obj = solve_callback_solution(model, cb_data)
            model[:callback_calls] += 1
    
            # Add a constraint if the current_obj is not optimal
            if follower_obj < current_obj * (1 + 1e-6)
                con = @build_constraint(f ≤ sum(c .* x̂) + sum(t .* x̂[i1]))
                MOI.submit(model, MOI.LazyConstraint(cb_data), con)
                push!(model[:vf_x], x̂)
            end
    
            # Log the current solution as heuristic
            isnothing(provider) || push!(provider, x̂, t̂)
        end
    end

    MOI.set(model, MOI.LazyConstraintCallback(), lazy_callback)
end

function solve_callback_solution(model, cb_data)
    t, f, follower = model[:t], model[:f], model[:follower]

    t̂ = callback_value.(cb_data, t)
    set_toll!(follower, t̂)
    optimize!(follower)

    follower_obj = objective_value(follower)
    current_obj = callback_value(cb_data, f)

    x̂ = round.(Int, value.(follower[:x]))

    return x̂, t̂, follower_obj, current_obj
end

function add_value_function_constraint!(model, x̂::Vector{<:Number})
    prob = model[:prob]
    t, f = model[:t], model[:f]
    c, i1 = base_costs(prob), collect(tolled(prob))

    @constraint(model, f ≤ sum(c .* x̂) + sum(t .* x̂[i1]))
end

add_value_function_constraint!(model, x_set::BitSet) =
    add_value_function_constraint!(model, convert_set_to_x(x_set, length(model[:x])))
