function DataFrames.rename!(df, ::DataFile{Val{Symbol("C&D")}})
    namemap = Dict("WE(1).Potential (V)"=>"Potential (V)",
                   "Time (s)"=>"Other Time (s)",
                   "Corrected time (s)"=>"Time (s)")
    rename!(df, namemap)
end

function find_pair(datafile, list, ending)
    findfirst(f -> filevalue(f) == filevalue(datafile) &&
                   foldervalue(f) == foldervalue(datafile) &&
                   endswith(f.filename, ending),
              list)
end

function add_CD(filename)
    parts = rsplit(filename, '.', limit=2)
    parts[1][1:end-1] * "CD." * parts[2]
end

function process_data(::Val{Symbol("C&D")}, data; insert_D, continue_col)
    done = Vector{Int}()
    for (i,f) in enumerate(data["C&D"])
        if i in done
            continue
        else
            push!(done, i)

            df = read_file(f)

            valid_idx = setdiff(axes(data["C&D"], 1), done)
            pair_idx = find_pair(f, data["C&D"], endswith(f.filename, "_C") ? "_D" : "_C")

            if isnothing(pair_idx)
                if endswith(f.filename, "_D")
                    pushfirst(df, insert_D)
                    write_file(f, df, ';')
                end
                continue
            end

            f_pair = data["C&D"][pair_idx]
            push!(done, pair_idx)

            df_pair = read_file(f_pair)
            df_C, df_D = endswith(f.filename, "_C") ? (df, df_pair) : (df_pair, df)
            df_CD, df_D = postprocess(f, df_C, df_D, insert_D, continue_col)

            new_name = add_CD(f.savename)
            mergedf = DataFile{Val{Symbol("C&D")}}(f.filename, new_name, f.units,
                f.legend_units, f.idx)

            write_file(mergedf, df_CD, ';')
            write_file(endswith(f.filename, "_D") ? f : f_pair, df_D, ';')
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

function postprocess(datafile::DataFile{Val{Symbol("C&D")}}, df_C, df_D, value, cont_col)
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
