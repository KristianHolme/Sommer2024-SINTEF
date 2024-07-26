using Glob, MAT

function read_setup_and_load_states(path; read_fun=read_MRST_output)
    
    ## read case setup
    case = setup_case_from_mrst(folder_path*".mat");
    model = case[1].model;
    # num_cells = model[:Reservoir].data_domain.representation.nc
    reservoir_states = read_fun(path)
    return model, reservoir_states    
end

function read_MRST_output(directory; field="rs", fieldSymbol=:Rs)
    if !endswith(directory, "multiphase")
        directory = joinpath(directory, "multiphase")
    end
    pattern = joinpath(directory, "state*.mat")
    pattern = "state*.mat"
    files = glob(pattern, directory)
    files = sort(files, by = x -> parse(Int, match(r"state(\d+)\.mat", basename(x)).captures[1]))
    num_files = length(files)
    states = Vector{Dict{Symbol, Any}}(undef, num_files)
    
    @showprogress for (i, file) in enumerate(files)
        matfile = matopen(file)
        data = read(matfile, "data")
        if haskey(data, field)
            values = vec(data[field])
            states[i] = Dict(fieldSymbol => values)
        else
            println("Field '$field' not found in file: $file")
        end
        close(matfile)
    end
    return states
end


function read_big_jutul_output(pth;field=:Rs, parts=3)
    if !endswith(pth, "output")
        pth = pth*"_output"
    end
    indices = Jutul.valid_restart_indices(pth)
    @info "reading $(indices[end]) states in $parts parts"
    states = Vector{Dict{Symbol, Any}}(undef, length(indices))
    section_size = Int(floor(length(indices)/parts))
    section_indices = [1; collect(1:parts-1); length(indices)]
    section_indices[2:end-1] = section_indices[2:end-1] .* section_size
    for section in 1:parts
        range = section_indices[section]:section_indices[section+1]
        temp_states = read_results(pth;read_states = true,
                                       read_reports = false,
                                       range = range)[1]
        for istep in range
            states[istep] = Dict(field => temp_states[istep - range[1]+1][:Reservoir][field])
        end
    end
    return states
end

function read_jutul_and_convert(pth)
    if !endswith(pth, "output")
        pth = pth*"_output"
    end
    reservoir_states, _ = read_results(output_path, read_reports=false); 
    for i in eachindex(reservoir_states)
        reservoir_states[i] = reservoir_states[i][:Reservoir]
    end
    return reservoir_states
end
