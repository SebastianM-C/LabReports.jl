function read_file(datafile, datarow=2, rename=true, delim=';')
    df = CSV.read(datafile.filename, delim=delim, datarow=datarow, copycols=true)
    rename && rename!(df, datafile)

    return df
end

function header(df, delim)
    buffer = ""
    col_names = names(df)
    sz = length(col_names)
    for (i, n) in enumerate(col_names)
        buffer *= string(n)
        if i < sz
            buffer *= delim
        end
    end

    return buffer * (@static Sys.iswindows() ? "\r\n" : '\n')
end

function write_file(datafile::DataFile, df, delim)
    ncols = length(eachcol(df))
    info = comment_value(datafile)
    units = join(datafile.units, delim)
    new_line = repeat(info * delim, ncols)
    new_line *= info

    write_file(df, new_line, datafile.savename, delim)
end

function write_file(df::AbstractDataFrame, extra, filename, delim)
    buffer = IOBuffer()
    nl = @static Sys.iswindows() ? "\r\n" : '\n'
    df |> CSV.write(buffer, delim=delim, writeheader=false, newline=nl)

    h = header(df, delim)
    file = String(take!(buffer))
    if extra isa Tuple
        content = h * join(extra, nl) * nl
    else
        content = h * extra * nl
    end

    open(filename, "w") do f
        write(f, content, file)
    end
    return nothing
end
