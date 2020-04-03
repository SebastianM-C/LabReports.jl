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
