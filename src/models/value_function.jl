function value_function_model(prob::PricingProblem; silent=false, threads=nothing, heuristic=true)
    model = base_model(prob; silent, threads)
    heuristic && add_heuristic_provider!(model)
    add_value_function_callback!(model; threads)
    return model
end

function add_value_function_callback!(model; threads=nothing)
    f = model[:f]
    ct = make_ct(model[:t], model[:prob])

    add_cutting_plane_callback!(model; threads) do cb_data, x̂
        con = @build_constraint(f ≤ ct' * x̂)
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
    end
end

function add_value_function_constraint!(model, x̂::Vector{<:Number})
    f = model[:f]
    ct = make_ct(model[:t], model[:prob])
    @constraint(model, f ≤ ct' * x̂)
end

add_value_function_constraint!(model, x_set::BitSet) =
    add_value_function_constraint!(model, convert_set_to_x(x_set, length(model[:x])))
