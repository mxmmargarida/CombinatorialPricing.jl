toll_bounds(prob::KnapsackPricing) = prob.base_values

function add_primal!(model::Model, prob::KnapsackPricing)
    x = model[:x]
    w = weights(prob)
    C = capacity(prob)
    @constraint(model, knapsack, w' * x ≤ C)
    return
end
