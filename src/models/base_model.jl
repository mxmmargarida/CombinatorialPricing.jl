function base_model(prob::PricingProblem; silent=false, threads=nothing, sdtol=1e-4,
    trivial_cuts=false, trivial_bound=false)

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

    # Connections to prevent unboundedness
    if trivial_cuts || trivial_bound
        model[:tollfree] = toll_free_solution(prob; threads)
        model[:nulltoll] = null_toll_solution(prob; threads)
    end

    if trivial_cuts
        add_value_function_constraint!(model, model[:tollfree])
        add_value_function_constraint!(model, model[:nulltoll])
    end

    if trivial_bound
        tollfree_cost = sum(c[collect(model[:tollfree])]; init=0.)
        nulltoll_cost = sum(c[collect(model[:nulltoll])]; init=0.)
        diff_est = tollfree_cost - nulltoll_cost
        @constraint(model, sum(tx) ≤ diff_est)
    end

    # Linearization
    @constraint(model, tx .≤ M[i1] .* x[i1])
    @constraint(model, t .- tx .≤ M[i1] .* (1 .- x[i1]))
    @constraint(model, t .- tx .≥ 0)

    # Problem-specific constraints
    add_primal!(model, prob)
    
    return model
end
