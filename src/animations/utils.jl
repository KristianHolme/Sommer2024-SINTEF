function ranges(states1, states_diff, states2)
    max_regular = -Inf
    min_regular = Inf

    max_diff = -Inf
    min_diff = Inf
    
    num_states = length(states1)

    for i = 1:num_states
        for regular_state in [states1, states2]
            max_regular = max(max_regular, maximum(regular_state[i][:Rs]))
            min_regular = min(min_regular, minimum(regular_state[i][:Rs]))
        end

        max_diff = max(max_diff, maximum(states_diff[i][:Rs]))
        min_diff = min(min_diff, minimum(states_diff[i][:Rs]))
    end
    return [[min_regular, max_regular], max(abs(min_diff), max_diff)]
end