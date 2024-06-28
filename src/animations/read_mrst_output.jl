using Glob, MAT
function readMRSTOutput(directory; field="rs")
    pattern = joinpath(directory, "state*.mat")
    pattern = "state*.mat"
    files = glob(pattern, directory)
    files = sort(files, by = x -> parse(Int, match(r"state(\d+)\.mat", basename(x)).captures[1]))
    state = Vector{Any}()
    
    for file in files
        matfile = matopen(file)
        data = read(matfile, "data")
        if haskey(data, field)
            values = data[field]
            push!(state, values)
        else
            println("Field '$field' not found in file: $file")
        end
        close(matfile)
    end
    return state
end
