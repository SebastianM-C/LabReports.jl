value_index(datafile::DataFile{Val{:EIS}}, filename) = !occursin(prefix, filename) ? 1 : 2

function process_data(::Val{:EIS}, data, (op, col, val))
    for f in data["EIS"]
        df = read_file(f)
        c = getproperty(df, col)
        fd = getindex(df, op.(c, val), :)

        write_file(f, fd, ';')
    end
end
