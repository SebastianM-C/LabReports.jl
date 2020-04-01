const prefix = "filtered_"

function read_file(datafile)
    df = CSV.read(datafile.filename, delim=';', copycols=true)
    rename!(df, datafile.namemap)
end

exclude(f) = occursin(prefix, f) || endswith(f, ".opj")

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

value_index(datafile, filename) = !occursin(prefix, filename) ? 3 : 4

function filevalue(datafile)
    filename = datafile.filename
    fn = basename(filename)
    parts = split(fn, '_')
    idx = value_index(datafile, filename)
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
    df |> CSV.write(buffer, delim=delim, writeheader=false)

    h = header(df, delim)
    file = String(take!(buffer))

    ncols = count(string(delim), h)
    info = comment_value(datafile)
    new_line = repeat(info * delim, ncols)
    new_line *= info * '\n'
    h *= new_line

    open(datafile.savename, "w") do f
        write(f, h, file)
    end
    return nothing
end
