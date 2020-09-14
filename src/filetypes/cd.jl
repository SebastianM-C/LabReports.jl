struct GalvanostaticChargeDischarge <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    is_charging::Bool
    I::Quantity
    porosity::Quantity
    exposure_time::Quantity
    round_idx::Int
    name_rules::NamedTuple
    spec::String
end

function GalvanostaticChargeDischarge(filename, savename, units, spec, name_rules)
    round_idx = 1
    spec = replace(spec, "{val}"=>"{I}")
    m = match_spec(spec, filename, parse_rules)
    isnothing(m) && @error "Specification string $spec did not match filename for $filename"

    is_charging = cd_status(m)
    I = parse_quantity(m, :I, name_rules)
    porosity = parse_quantity(m, :porosity, name_rules, Int)
    exposure_time = parse_quantity(m, :exposure_time, name_rules)

    GalvanostaticChargeDischarge(filename, savename, units, is_charging,
        I, porosity, exposure_time, round_idx, name_rules, spec)
end

function cd_status(match)
    if isempty(match[:cd_type])
        return false
    end
    cd_part = match[:cd_type]
    return uppercase(cd_part) == "C"
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
    spec = datafile.spec

    m = match_spec(spec, filename, parse_rules)
    idx = m.offsets[findfirst(i->i==m[:cd_type], m.captures)]
    filename[1:idx-1] * "CD" * (idx == length(filename) ? "" : filename[idx+1:end])
end

function process_data(datafiles::Vector{GalvanostaticChargeDischarge}; insert_D, continue_col, filter=false)
    for data in datafiles
        df = read_file(data)
        pair_idx = find_pair(data, datafiles)
        if data.is_charging
            if !isnothing(pair_idx)
                pair = datafiles[pair_idx]
                pair_df = read_file(pair)

                df_CD, df_D = postprocess(data, df, pair_df, insert_D, continue_col)
                new_name = name_with_CD(data)
                merged = GalvanostaticChargeDischarge(data.filename, new_name, data.units, data.spec, data.name_rules)

                if filter
                    df_CD = df_CD[df_CD[!, :Potential] .< 0, :]
                end

                write_file(merged, df_CD, ';')
                write_file(pair, df_D, ';')
            end
        else
            pushfirst(df, insert_D)
            write_file(data, df, ';')
        end
    end

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

function select_region(data::GalvanostaticChargeDischarge, ::Val{:first_cd})
    df = read_file(data, processed_datarow, false)
    V = df[!, "Potential"]
    a_idx = findfirst(v->v>0, V)
    b_idx = findfirst(v->v<0, OffsetArray(V[a_idx:end], a_idx:lastindex(V))) - 1

    write_file(data, df[a_idx:b_idx,:], ';', replace(data.savename, ".dat"=>"_1.5.txt"))
end

function ir_drop(data::GalvanostaticChargeDischarge)
    df = read_file(data, processed_datarow, false)

    V = df[!, "Potential"]
    V_max, idx = findmax(V)
    ΔV = V_max - V[idx+1]
    I = data.I

    I, ΔV
end

function ir_drop(grouped, folder)
    for datafiles in values(grouped)
        I_ΔV = ir_drop.(datafiles)
        I = [iv[1] for iv in I_ΔV]
        ΔV = [iv[2] for iv in I_ΔV]

        df = DataFrame(:I=>ustrip.(u"mA", I), :ΔV=>ΔV)

        units = "mA,V"
        datafile = datafiles[1]
        porosity = comment_line(datafile, foldervalue, ",", 2) * ","
        exposure_time = replace(comment_line(datafile, metadata, ",", 2), "minute"=>"minutes")
        filename = joinpath(folder, string(ustrip(datafile.porosity)) * "_ir_drop.csv")
        write_file(df, (units, porosity, exposure_time), filename, ",")
    end
end
