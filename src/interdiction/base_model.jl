function base_model(prob::KnapsackInterdiction; silent=false, threads=nothing)
    model = blank_model(; silent, threads)
    model[:prob] = prob

    n = num_items(prob)
    CU = upper_cap(prob)
    wU = upper_weights(prob)

    @variable(model, t[i=1:n], Bin)
    @variable(model, x[i=1:n], Bin)
    @variable(model, g <= 0)

    @objective(model, Max, g)

    # Upper level knapsack
    @constraint(model, upper_knapsack, wU' * t <= CU)
    
    return model
end

make_ct(t, prob::KnapsackInterdiction) = -profits(prob) .* (1 .- t)

function _leader_objective(prob::KnapsackInterdiction, x, t)
    p = profits(prob)
    return -sum(p .* (1 .- t) .* x)
end
