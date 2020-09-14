function read_file(datafile, datarow=2, rename=true, delim=';')
    df = CSV.read(datafile.filename, delim=delim, datarow=datarow, copycols=true)
    rename && strip_units!(df)
    rename && rename!(df, datafile)

    return df
end

function header(df, delim)
    buffer = join(replace_unicode.(names(df)), delim)

    return buffer * (@static Sys.iswindows() ? "\r\n" : '\n')
end

function comment_line(datafile, f, delim, ncols)
    info = comment_value(f, datafile)

    join(repeat([info], ncols), delim)
end

function write_file(datafile::AbstractDataFile, df, delim, filename=datafile.savename)
    ncols = length(eachcol(df))
    file_line = comment_line(datafile, filevalue, delim, ncols)
    folder_line = comment_line(datafile, foldervalue, delim, ncols) * delim
    metadata_line = comment_line(datafile, metadata, delim, ncols)
    units = to_origin(join(datafile.units, delim))
    metadata_line = replace(metadata_line, "minute"=>"minutes")

    write_file(df, (units, file_line, folder_line, metadata_line), filename, delim)
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
