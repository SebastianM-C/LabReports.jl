function read_file(datafile)
    df = CSV.read(datafile.filename, delim=';', copycols=true)
    rename!(df, datafile)

    return df
end

function write_file(datafile, df, delim)
    buffer = IOBuffer()
    nl = @static Sys.iswindows() ? "\r\n" : '\n'
    df |> CSV.write(buffer, delim=delim, writeheader=false, newline=nl)

    h = header(df, delim)
    file = String(take!(buffer))

    ncols = count(string(delim), h)
    info = comment_value(datafile)
    new_line = repeat(info * delim, ncols)
    new_line *= info * nl
    h *= new_line

    open(datafile.savename, "w") do f
        write(f, h, file)
    end
    return nothing
end
