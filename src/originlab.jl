function read_file(datafile)
    df = CSV.read(datafile.filename, delim=';', copycols=true)
    rename!(df, datafile)

    return df
end

exclude(f, ext) = occursin(ext, f) || endswith(f, ".opj")

function to_origin(str)
    new_string = ""
    for letter in str
        if !isascii(letter)
            c = string(codepoint(letter), base=16, pad=4)
            new_string *= "\\x($c)"
        else
            new_string *= letter
        end
    end
    return new_string
end

value_index(datafile) = 3

function filevalue(datafile)
    filename = datafile.filename
    fn = basename(filename)
    parts = split(fn, '_')
    idx = value_index(datafile)
    replace(parts[idx], " "=>"")
end

function comment_value(datafile)
    u = datafile.legend_units
    idx = datafile.idx

    value = filevalue(datafile)
    unicode_val = si_round(uparse(value*u), idx)
    return to_origin(unicode_val)
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
