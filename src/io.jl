function read_file(datafile, datarow=2, rename=true, delim=';')
    df = CSV.read(datafile.filename, delim=delim, datarow=datarow, copycols=true)
    rename && rename!(df, datafile)

    return df
end

function header(df, delim)
    buffer = join(names(df), delim)

    return buffer * (@static Sys.iswindows() ? "\r\n" : '\n')
end

function write_file(datafile::AbstractDataFile, df, delim)
    ncols = length(eachcol(df))
    info = comment_value(datafile)
    units = join(datafile.units, delim)
    new_line = join(repeat([info], ncols), delim)

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
