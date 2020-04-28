function series_with_common_value(folder, type, kind; read_processed=false, find_val=findmin)
    if read_processed
        data = find_files(folder, exclude_with=r"!", select_with=".dat", rename=false)
    else
        data = find_files(folder)
    end

    common = common_values(data[type])
    val, idx = find_val(parse.(Float64, common))
    minval = common[idx]

    files = files_with_val(data[type], minval)

    sort!(files, lt=(a,b)->parse(Int,foldervalue(a)) < parse(Int,foldervalue(b)))
    dfs = DataFrame[]
    selected_files = Vector{eltype(files)}()

    for file in files
        if occursin(kind, file.filename)
            if read_processed
                df = LabReports.read_file(file, 3, false)
            else
                df = LabReports.read_file(file)
            end
            push!(dfs, df)
            push!(selected_files, file)
        end
    end

    return dfs, selected_files
end
