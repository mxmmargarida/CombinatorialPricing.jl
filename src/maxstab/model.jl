follower_sense(::MaxStableSetPricing) = MAX_SENSE

toll_bounds(prob::MaxStableSetPricing) = prob.base_values

function add_primal!(model::Model, prob::MaxStableSetPricing)
    x = model[:x]
    g = graph(prob)
    A = incidence_matrix(g)'
    b = ones(ne(g))
    @constraint(model, stable_set, A * x .≤ b)
    return
end
