function value_function_model(prob::PricingProblem; silent=false, threads=nothing, heuristic=true, sdtol=1e-4,
    reset_follower=false, trivial_cuts=false, trivial_bound=false)
    
    model = base_model(prob; silent, threads, sdtol, trivial_cuts, trivial_bound)
    heuristic && add_heuristic_provider!(model)
    add_value_function_callback!(model; threads, reset_follower)
    return model
end

function add_value_function_callback!(model; threads=nothing, reset_follower=false)
    g = model[:g]
    ct = make_ct(model[:t], model[:prob])

    add_cutting_plane_callback!(model; threads, reset_follower) do cb_data, x̂
        con = @build_constraint(g ≤ ct' * x̂)
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
    end
end

function add_value_function_constraint!(model, x̂::Vector{<:Number})
    g = model[:g]
    ct = make_ct(model[:t], model[:prob])
    @constraint(model, g ≤ ct' * x̂)
end

add_value_function_constraint!(model, x_set::BitSet) =
    add_value_function_constraint!(model, convert_set_to_x(x_set, length(model[:x])))
