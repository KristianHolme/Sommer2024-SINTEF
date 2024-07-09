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

function format_time(seconds;include_days=false)
    days_in_year = 365
    seconds_in_day = 86400
    seconds_in_year = days_in_year * seconds_in_day

    years = floor(Int, seconds / seconds_in_year)
    days = floor(Int, (seconds % seconds_in_year) / seconds_in_day)
    formatted_days = lpad(days, 3, '0')
    if include_days
        return "$years years, $formatted_days days"
    else
        return "$years years"
    end
end

function read_states_and_calc_diff(path1, path2)
    reservoir_states_1 = readMRSTOutput(path1*"/multiphase")
    reservoir_states_2 = readMRSTOutput(path2*"/multiphase")

    num_states = length(reservoir_states_1)
    # Calculate difference between states
    difference = Vector{Dict{Symbol, Any}}(undef, num_states)
    num_cells = model[:Reservoir].data_domain.representation.nc

    for i in eachindex(reservoir_states_1)
        difference[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))
        difference[i][:Rs] =  vec(reservoir_states_1[i] - reservoir_states_2[i])
    end
    # Format states for Plotting
    states1 = Vector{Dict{Symbol, Any}}(undef, num_states)
    states2 = Vector{Dict{Symbol, Any}}(undef, num_states)
    for i in eachindex(reservoir_states_1)
        states1[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))
        states2[i] = Dict(:Rs=> Vector{Float64}(undef, num_cells))

        states1[i][:Rs] =  vec(reservoir_states_1[i])
        states2[i][:Rs] =  vec(reservoir_states_2[i])
    end
    return states1, states2, difference
end