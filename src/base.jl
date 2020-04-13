function find_files(folder, types = ["CV", "C&D", "EIS"], ext=".dat")
    contents = readdir(folder, join=true)
    dirs = contents[isdir.(contents)]
    data = Dict{String,Vector{DataFile}}()
    for dir in dirs
        files = readdir(dir, join=true)
        files = files[isfile.(files)]

        for file in files
            for type in types
                if occursin(type, file) && !exclude(file, ext)
                    if haskey(data, type)
                        push!(data[type], DataFile(file, ext))
                    else
                        push!(data, type=>[DataFile(file, ext)])
                    end
                end
            end
        end
    end

    return data
end

process_data(type::String, data; args...) = process_data(Val(Symbol(type)), data; args...)

value_index(datafile) = 3

function filevalue(datafile)
    filename = datafile.filename
    fn = basename(filename)
    parts = split(fn, '_')
    idx = value_index(datafile)
    replace(parts[idx], " "=>"")
end

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

    return buffer * (@static Sys.iswindows() ? "\r\n" : '\n')
end

function clear(dir, to_delete)
    for (root,dirs,files) in walkdir(dir)
        for file in files
            if occursin(to_delete, file)
                rm(joinpath(root, file))
                @info "Deleted $(joinpath(root, file))"
            end
        end
    end
end
