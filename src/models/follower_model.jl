function follower_model(prob::PricingProblem; silent=false, threads=nothing)
    model = blank_model(; silent, threads)
    model[:prob] = prob

    n = num_items(prob)
    v = base_values(prob)

    sense = follower_sense(prob)

    @variable(model, x[i=1:n], Bin)

    # Follower objective
    if sense == MIN_SENSE
        @objective(model, Min, v' * x)
    elseif sense == MAX_SENSE
        @objective(model, Max, v' * x)
    else
        throw(ErrorException("Invalid follower sense: $sense"))
    end

    # Stable set constraints
    add_primal!(model, prob)
    
    return model
end
