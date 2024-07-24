function read_big_output(pth;field=:Rs, parts=3)
    indices = Jutul.valid_restart_indices(pth)
    @info "reading $(indices[end]) states in $parts parts"
    states = Vector{Dict{Symbol, Any}}(undef, length(indices))
    section_size = Int(floor(length(indices)/parts))
    section_indices = [1; collect(1:parts-1); length(indices)]
    section_indices[2:end-1] = section_indices[2:end-1] .* section_size
    for section in 1:parts
        range = section_indices[section]:section_indices[section+1]
        temp_states = read_results(pth;read_states = true,
                                   read_reports=false,
                                   range = range)[1]
        for istep in range
            states[istep] = Dict(field => temp_states[istep - range[1]+1][:Reservoir][field])
        end
    end
    return states
end