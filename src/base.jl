function find_files(folder, types = ["CV", "C&D", "EIS"], delim=';', ext=".dat")
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
                        push!(data[type], DataFile(file, ext, delim))
                    else
                        push!(data, type=>[DataFile(file, ext, delim)])
                    end
                end
            end
        end
    end

    return data
end

function files_with_val(datafiles, val)
    files = DataFile[]
    for file in datafiles
        if filevalue(file) == val
            push!(files, file)
        end
    end

    return files
end

foldervalue(datafile) = splitpath(datafile.filename)[2]

function filevalues(datafiles)
    vals = Dict{String,Set{String}}()
    for file in datafiles
        fdv = foldervalue(file)
        fv = filevalue(file)
        if haskey(vals, fdv)
            push!(vals[fdv], fv)
        else
            push!(vals, fdv=>Set{String}([fv]))
        end
    end

    return vals
end

function common_values(data)
    fvs = filevalues(data)

    common = collect(fvs[first(keys(fvs))])

    for (k,v) in fvs
        intersect!(common, v)
    end

    return common
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
