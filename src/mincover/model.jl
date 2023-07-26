function toll_bounds(prob::MinSetCoverPricing)
    global_tollfree = toll_free_cost(prob)

    bounds = zeros(num_items(prob))
    for i in tolled(prob)
        set = prob.sets[i]

        inset = collect(set)
        exset = setdiff(1:prob.num_elements, inset)
        inprob = restrict(prob, inset)
        exprob = restrict(prob, exset)

        M1 = global_tollfree - null_toll_cost(exprob)
        M2 = toll_free_cost(inprob) - base_costs(prob)[i]
        bounds[i] = max(min(M1, M2), 0.)
    end

    return bounds
end

function add_primal!(model::Model, prob::MinSetCoverPricing)
    x = model[:x]
    A = incidence_matrix(prob.sets, prob.num_elements)
    b = ones(prob.num_elements)
    @constraint(model, min_cover, A * x .≥ b)
    return
end
