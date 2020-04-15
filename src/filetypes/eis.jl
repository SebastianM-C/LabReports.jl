function DataFrames.rename!(df, ::DataFile{Val{:EIS}}) end

value_index(datafile::DataFile{Val{:EIS}}) = 1

function process_data(::Val{:EIS}, data; select)
    col, op, val = select
    for f in data["EIS"]
        df = read_file(f)
        c = getproperty(df, col)
        fd = getindex(df, op.(c, val), :)

        write_file(f, fd, ';')
    end
end
