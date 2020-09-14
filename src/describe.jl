function find_files(folder, spec, ext=".dat";
                    delim=';',
                    exclude_with=[ext],
                    select_with="",
                    exclude_dirs=[],
                    extra_rules=(type=Dict(), name=NamedTuple()))
    # dirs = setdiff(dirs_in_folder(folder, true), exclude_dirs)
    data = Vector{AbstractDataFile}()

    # for dir in dirs
    #     files = readdir(dir, join=true)
    #     files = files[isfile.(files)]

    #     for file in files
    #         if occursin(select_with, file) && !exclude(file, exclude_with)
    #             push!(data, datafile(file, ext, delim, extra_rules))
    #         end
    #     end
    # end

    for (root, dirs, files) in walkdir(folder)
        if basename(root) ∈ exclude_dirs
            continue
        end

        for file in files
            if occursin(select_with, file) && !exclude(file, exclude_with)
                full_path = joinpath(root, file)
                push!(data, datafile(full_path, spec, ext, delim, extra_rules))
            end
        end
    end

    return data
end

foldervalue(filename) = splitpath(filename)[2]
foldervalue(datafile::AbstractDataFile) = datafile.porosity

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

function filevalue(filename, name_rules, key)
    if haskey(name_rules, :processed_ext)
        filename = replace(filename, name_rules.processed_ext=>"")
    end
    fn = splitpath(filename)[]
    parts = split(fn, name_rules.separator)
    val = parts[getproperty(name_rules, key)]

    if haskey(name_rules, :replace_str)
        for p in pairs(name_rules.replace_str)
            val = replace(val, p)
        end
    end

    return val
end

filevalue(f::CiclycVoltammetry) = f.scan_rate
filevalue(f::GalvanostaticChargeDischarge) = f.I
filevalue(f::ElectrochemicalImpedanceSpectroscopy) = f.U

filetype(::CiclycVoltammetry) = "CV"
filetype(::GalvanostaticChargeDischarge) = "C&D"
filetype(::ElectrochemicalImpedanceSpectroscopy) = "EIS"

metadata(datafile) = datafile.exposure_time

function dirs_in_folder(folder, keep_root)
    contents = readdir(folder, join=true)
    dirs = contents[isdir.(contents)]
    return keep_root ? dirs : basename.(dirs)
end

function files_with_val(datafiles, val)
    files = AbstractDataFile[]
    for file in datafiles
        if filevalue(file) == val
            push!(files, file)
        end
    end

    return files
end

function common_values(data)
    fvs = filevalues(data)

    common = collect(fvs[first(keys(fvs))])

    for (k,v) in fvs
        intersect!(common, v)
    end

    return common
end

function DataFrames.groupby(f, datafiles::Vector{T}) where {T <: AbstractDataFile}
    data = Dict{Any,Vector{AbstractDataFile}}()
    for df in datafiles
        i = f(df)
        if haskey(data, i)
            push!(data[i], df)
        else
            data[i] = [df]
        end
    end
    return data
end

function results(folder, type, parameter_val, file_val; processed=true, reduction=identity)
    if processed
        data = find_files(folder, exclude_with=r"!", select_with=".dat", rename=false)
        ext = ".dat"
    else
        data = find_files(folder)
        ext = ""
    end

    grouped = groupbyfolder(data[type])
    files = files_with_val(grouped[parameter_val], file_val, ext)
    datafile = only(reduction(files))

    if processed
        df = read_file(datafile, 3, false)
    else
        df = read_file(datafile)
    end

    return datafile, df
end

function strip_units!(df)
    re = r"(?<name>^.*)(?<unit>( .*))"
    n = names(df)
    new_names = replace.(n, re=>s"\g<name>")
    rename!(df, new_names)
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
