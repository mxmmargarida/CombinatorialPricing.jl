function follower_model(prob::KnapsackInterdiction; silent=false, threads=nothing)
    model = blank_model(; silent, threads)
    model[:prob] = prob

    n = num_items(prob)
    CL = lower_cap(prob)
    wL = lower_weights(prob)
    p = profits(prob)

    @variable(model, x[i=1:n], Bin)

    # Follower objective
    @objective(model, Min, -p' * x)

    # Lower-level knapsack
    @constraint(model, lower_knapsack, wL' * x <= CL)
    
    return model
end

function set_toll!(model::Model, prob::KnapsackInterdiction, toll)
    x = model[:x]
    p = profits(prob)
    @objective(model, Min, -sum(p .* (1 .- toll) .* x))
end
