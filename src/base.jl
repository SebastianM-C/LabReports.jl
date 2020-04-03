function find_files(folder, types = ["CV", "C&D", "EIS"])
    contents = readdir(folder, join=true)
    dirs = contents[isdir.(contents)]
    data = Dict{String,Vector{DataFile}}()
    for dir in dirs
        files = readdir(dir, join=true)
        files = files[isfile.(files)]

        for file in files
            for type in types
                if occursin(type, file) && !exclude(file)
                    if haskey(data, type)
                        push!(data[type], DataFile(file))
                    else
                        push!(data, type=>[DataFile(file)])
                    end
                end
            end
        end
    end

    return data
end

process_data(type::String, data; args...) = process_data(Val(Symbol(type)), data; args...)

function header(df, delim)
    buffer = ""
    col_names = names(df)
    sz = length(col_names)
    for (i, n) in enumerate(col_names)
        buffer *= string(n)
        if i < sz
            buffer *= delim
        end
    end

    return buffer * '\n'
end

function clear(dir, to_delete)
    for (root,dirs,files) in walkdir(dir)
        for file in files
            if occursin(to_delete, file)
                rm(joinpath(root, file))
            end
        end
    end
end
