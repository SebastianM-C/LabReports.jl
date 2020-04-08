function DataFrames.rename!(df, ::DataFile{Val{:CV}})
    namemap = Dict("WE(1).Current (A)"=>"Current (mA)",
                   "WE(1).Potential (V)"=>"Potential (V)")
    rename!(df, namemap)
end

function process_data(::Val{:CV}, data; select)
    col, op, val = select
    for f in data["CV"]
        df = read_file(f)
        c = getproperty(df, col)
        fd = getindex(df, op.(c, val), :)
        push!(df, df[1, :])

        write_file(f, fd, ';')
    end
end
