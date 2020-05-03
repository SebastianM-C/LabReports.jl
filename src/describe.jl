function find_files(folder, ext=".dat", delim=';', types = ["CV", "C&D", "EIS"];
        exclude_with=ext, select_with="", rename=true)

    dirs = dirs_in_folder(folder, true)
    data = Dict{String,Vector{DataFile}}()
    for dir in dirs
        files = readdir(dir, join=true)
        files = files[isfile.(files)]

        for file in files
            for type in types
                if occursin(type, file) && occursin(select_with, file) && !exclude(file, exclude_with)
                    if haskey(data, type)
                        push!(data[type], DataFile(file, ext, delim, rename))
                    else
                        push!(data, type=>[DataFile(file, ext, delim, rename)])
                    end
                end
            end
        end
    end

    return data
end

function dirs_in_folder(folder, keep_root)
    contents = readdir(folder, join=true)
    dirs = contents[isdir.(contents)]
    return keep_root ? dirs : basename.(dirs)
end

function files_with_val(datafiles, val, ext="")
    files = DataFile[]
    for file in datafiles
        if filevalue(file, ext) == val
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

function filevalue(datafile, ext="")
    filename = isempty(ext) ? datafile.filename : replace(datafile.filename, ext=>"")
    fn = basename(filename)
    parts = split(fn, '_')
    idx = value_index(datafile)
    replace(parts[idx], " "=>"")
end

function groupbyfolder(datafiles)
    data = Dict{String,Vector{DataFile}}()
    for df in datafiles
        f = foldervalue(df)
        if haskey(data, f)
            push!(data[f], df)
        else
            data[f] = [df]
        end
    end
    return data
end

function results(folder, type, parameter_val, file_val; processed=true)
    if processed
        data = find_files(folder, exclude_with=r"!", select_with=".dat", rename=false)
        ext = ".dat"
    else
        data = find_files(folder)
        ext = ""
    end

    grouped = groupbyfolder(data[type])
    datafile = only(files_with_val(grouped[parameter_val], file_val, ext))

    if processed
        df = read_file(datafile, 3, false)
    else
        df = read_file(datafile)
    end

    return datafile, df
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
