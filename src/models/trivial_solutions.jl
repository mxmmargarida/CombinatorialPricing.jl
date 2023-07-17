function toll_free_solution(prob::PricingProblem; silent=true, threads=1)
    model = follower_model(prob; silent, threads)
    x = model[:x]
    fix.(x[collect(tolled(prob))], 0, force=true)
    optimize!(model)
    return convert_x_to_set(value.(x))
end

function null_toll_solution(prob::PricingProblem; silent=true, threads=1)
    model = follower_model(prob; silent, threads)
    optimize!(model)
    return convert_x_to_set(value.(model[:x]))
end

function difference_estimate(prob::PricingProblem; silent=true, threads=1)
    tollfree = toll_free_solution(prob; silent, threads)
    nulltoll = null_toll_solution(prob; silent, threads)
    costs = base_costs(prob)
    return sum(costs[collect(tollfree)]; init=0.) - sum(costs[collect(nulltoll)]; init=0.)
end
