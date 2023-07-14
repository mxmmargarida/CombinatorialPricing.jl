"""
    follower_sense(prob::PricingProblem) -> MOI.OptimizationSense

Return the objective sense of the follower problem, either `MIN_SENSE` or `MAX_SENSE`.
"""
function follower_sense end

"""
    toll_bounds(prob::PricingProblem) -> Vector{Float64}

Get the upper bounds of the toll prices. The entries corresponding to the toll-free items are ignored.
"""
function toll_bounds end

"""
    add_primal!(model::Model, prob::PricingProblem)

Add the primal constraints to the model. The variables for the selectable items are provided as `x`.
"""
function add_primal! end
