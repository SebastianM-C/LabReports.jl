struct GalvanostaticChargeDischarge <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    is_charging::Bool
    I::Quantity
    porosity::Quantity
    round_idx::Int
    name_rules::NamedTuple
end

function GalvanostaticChargeDischarge(filename, savename, units, name_rules)
    is_charging = cd_status(filename, name_rules)
    round_idx = 1
    I = parse(Float64, filevalue(filename, name_rules)) * u"A"
    porosity = parse(Float64, foldervalue(filename)) * u"mA/cm^2"

    GalvanostaticChargeDischarge(filename, savename, units, is_charging, I, porosity, round_idx, name_rules)
end

function cd_status(filename, name_rules)
    name_parts = split(basename(filename), "_")
    if length(name_parts) < name_rules.cd_location
        return false
    end
    cd_part = name_parts[name_rules.cd_location]
    return cd_part == "C"
end

function DataFrames.rename!(df, ::GalvanostaticChargeDischarge)
    namemap = Dict("WE(1).Potential"=>"Potential",
                   "Time"=>"Other_Time",
                   "Corrected time"=>"Time")
    rename!(df, namemap)
end

function find_pair(datafile, list)
    findfirst(f -> filevalue(f) == filevalue(datafile) &&
                   foldervalue(f) == foldervalue(datafile) &&
                   !f.is_charging,
              list)
end

function name_with_CD(datafile)
    filename = datafile.savename
    name_rules = datafile.name_rules

    parts = rsplit(filename, '.', limit=2)
    name_parts = split(basename(parts[1]), "_")
    name_parts[name_rules.cd_location] = "CD"
    name = joinpath(dirname(parts[1]), join(name_parts, "_"))

    name * "." * parts[2]
end

function process_data(datafiles::Vector{GalvanostaticChargeDischarge}; insert_D, continue_col)
    for data in datafiles
        df = read_file(data)
        pair_idx = find_pair(data, datafiles)
        if data.is_charging
            if !isnothing(pair_idx)
                pair = datafiles[pair_idx]
                pair_df = read_file(pair)

                df_CD, df_D = postprocess(data, df, pair_df, insert_D, continue_col)
                new_name = name_with_CD(data)
                merged = GalvanostaticChargeDischarge(data.filename, new_name, data.units, data.name_rules)

                write_file(merged, df_CD, ';')
                write_file(pair, df_D, ';')
            end
        else
            pushfirst(df, insert_D)
            write_file(data, df, ';')
        end
    end

    # done = Vector{Int}()
    # for (i,f) in enumerate(data["C&D"])
    #     if i in done
    #         continue
    #     else
    #         push!(done, i)

    #         df = read_file(f)

    #         valid_idx = setdiff(axes(data["C&D"], 1), done)
    #         pair_idx = find_pair(f, data["C&D"], endswith(f.filename, "_C") ? "_D" : "_C")

    #         if isnothing(pair_idx)
    #             if endswith(f.filename, "_D")
    #                 pushfirst(df, insert_D)
    #                 write_file(f, df, ';')
    #             end
    #             continue
    #         end

    #         f_pair = data["C&D"][pair_idx]
    #         push!(done, pair_idx)

    #         df_pair = read_file(f_pair)
    #         df_C, df_D = endswith(f.filename, "_C") ? (df, df_pair) : (df_pair, df)
    #         df_CD, df_D = postprocess(f, df_C, df_D, insert_D, continue_col)

    #         new_name = add_CD(f.savename)
    #         mergedf = DataFile{Val{Symbol("C&D")}}(f.filename, new_name, f.units,
    #             f.legend_units, f.idx)

    #         write_file(mergedf, df_CD, ';')
    #         write_file(endswith(f.filename, "_D") ? f : f_pair, df_D, ';')
    #     end
    # end

    return nothing
end

function pushfirst(df, value)
    types = eltype.(eachcol(df))
    line = (Vector{types[i]}([v]) for (i,v) in enumerate(value))
    to_add = DataFrame(;zip(propertynames(df), line)...)
    append!(to_add, df)
end

function postprocess(datafile::GalvanostaticChargeDischarge, df_C, df_D, value, cont_col)
    # Insert values in _D file
    df_D_mod = pushfirst(df_D, value)
    # Append column with types
    df_C[!, :Type] .= "C"
    df_D[!, :Type] .= "D"
    # Add last value of cont_col form _C to _D values
    last_time = df_C[end, cont_col]
    df_D[!, cont_col] .+= last_time
    # Append DataFrames
    append!(df_C, df_D)
    return df_C, df_D_mod
end
