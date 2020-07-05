function read_file(datafile, datarow=2, rename=true, delim=';')
    df = CSV.read(datafile.filename, delim=delim, datarow=datarow, copycols=true)
    rename && strip_units!(df)
    rename && rename!(df, datafile)

    return df
end

function header(df, delim)
    buffer = join(names(df), delim)

    return buffer * (@static Sys.iswindows() ? "\r\n" : '\n')
end

function write_file(datafile::AbstractDataFile, df, delim)
    ncols = length(eachcol(df))
    file_info = comment_value(filevalue, datafile)
    file_line = join(repeat([file_info], ncols), delim)
    folder_info = comment_value(foldervalue, datafile)
    folder_line = join(repeat([folder_info], ncols), delim) * delim
    units = to_origin(join(datafile.units, delim))

    write_file(df, (units, file_line, folder_line), datafile.savename, delim)
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
