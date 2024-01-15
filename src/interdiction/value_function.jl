function value_function_model(prob::KnapsackInterdiction; silent=false, threads=nothing,
    heuristic=true, reset_follower=false)
    
    model = base_model(prob; silent, threads)
    heuristic && add_heuristic_provider!(model)
    add_value_function_callback!(model; threads, reset_follower)
    return model
end
