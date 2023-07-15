function follower_model(prob::PricingProblem; silent=false, threads=nothing)
    model = blank_model(; silent, threads)
    model[:prob] = prob

    n = num_items(prob)
    c = base_costs(prob)

    @variable(model, x[i=1:n], Bin)

    # Follower objective
    @objective(model, Min, c' * x)

    # Stable set constraints
    add_primal!(model, prob)
    
    return model
end

function set_toll!(model::Model, toll)
    prob = model[:prob]
    x = model[:x]
    c = base_costs(prob)
    t = expand_t(toll, prob)
    @objective(model, Min, (c + t)' * x)
end
