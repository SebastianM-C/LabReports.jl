exclude(f, ext) = occursin(ext, f) || endswith(f, ".opj")

function replace_unicode(str)
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

function replace_powers(str)
    inv_one = r"(?<pre>[a-zA-Z]+) (?<unit>[a-zA-Z]+)\^-1"
    inv_pre = r"(?<pre>[a-zA-Z]+) (?<unit>[a-zA-Z]+)\^-(?<power>[2-9]+)"
    power_only_unit = r"(?<unit>[a-zA-Z]+)\^(?<power>-?[1-9]+)"
    str = replace(str, inv_one=>s"\g<pre>/\g<unit>")
    str = replace(str, inv_pre=>s"\g<pre>/\g<unit>\\+(\g<power>)")
    str = replace(str, power_only_unit => s"\g<unit>\\+(\g<power>)")

    return str
end

function to_origin(str)
    str = replace_powers(str)
    replace_unicode(str)
end

function comment_value(datafile)
    value = filevalue(datafile)
    unicode_val = si_round(value, datafile.round_idx)
    return to_origin(unicode_val)
end
