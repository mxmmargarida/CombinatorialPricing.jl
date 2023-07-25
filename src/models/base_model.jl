function base_model(prob::PricingProblem; silent=false, threads=nothing, sdtol=1e-4)
    model = blank_model(; silent, threads)
    model[:prob] = prob
    model[:sdtol] = sdtol

    n = num_items(prob)
    i1 = collect(tolled(prob))
    c = base_costs(prob)

    model[:toll_bounds] = M = toll_bounds(prob)

    @variable(model, t[i=i1] ≥ 0, upper_bound=M[i])
    @variable(model, x[i=1:n], Bin)
    @variable(model, tx[i=i1] ≥ 0)
    @variable(model, f)
    @variable(model, g)

    @objective(model, Max, sum(tx))

    # Follower objective
    @constraint(model, primalobj, f == c' * x + sum(tx))
    @constraint(model, strongdual, f ≤ g + sdtol)

    # Linearization
    @constraint(model, tx .≤ M[i1] .* x[i1])
    @constraint(model, t .- tx .≤ M[i1] .* (1 .- x[i1]))
    @constraint(model, t .- tx .≥ 0)

    # Problem-specific constraints
    add_primal!(model, prob)
    
    return model
end
