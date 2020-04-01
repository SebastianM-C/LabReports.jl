function find_pair(val, list, ending)
    findfirst(f->filevalue(f)==val && endswith(f.filename, ending), list)
end

function process_data(::Val{Symbol("C&D")}, data, insert_vals, cont_col)
    done = Vector{Int}()
    for (i,f) in enumerate(data["C&D"])
        if i in done
            continue
        else
            push!(done, i)

            val = filevalue(f)
            valid_idx = setdiff(axes(data["C&D"], 1), done)
            pair_idx = find_pair(val, data["C&D"], endswith(f.filename, "_C") ? "_D" : "_C")
            if isnothing(pair_idx)
                continue
            end
            pair = data["C&D"][pair_idx]
            push!(done, pair_idx)

            df = read_file(f)
            pair_df = read_file(pair)
            df_C, df_D = endswith(f.filename, "_C") ? (df, pair_df) : (pair_df, df)
            df_CD, df_D = postprocess(f, df_C, df_D, insert_vals, cont_col)

            new_name = f.savename[1:end-2]
            mergedf = DataFile{Val{Symbol("C&D")}}(f.filename, new_name, f.namemap,
                f.units, f.legend_units, f.idx)

            write_file(mergedf, df_CD, ';')
            write_file(endswith(f.filename, "_D") ? f : pair, df_D, ';')
        end
    end

    return nothing
end

function postprocess(datafile::DataFile{Val{Symbol("C&D")}}, df_C, df_D, vals, cont_col)
    # Insert values in _D file
    types = eltype.(eachcol(df_D))
    line = (Vector{types[i]}([v]) for (i,v) in enumerate(vals))
    to_add = DataFrame(;zip(names(df_D), line)...)
    df_D_mod = append!(to_add, df_D)
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
