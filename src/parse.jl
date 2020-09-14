const NUMERICAL_VALUE = maybe(zero_or_more(DIGIT)) * maybe(".") * zero_or_more(DIGIT) *
                        maybe("e" * maybe(["+","-"]) * one_or_more(DIGIT))

const LITERAL_VALUE = one_or_more(LETTER) * maybe("&") * zero_or_more(LETTER)

const PARSE_FORMAT = "{" * capture(one_or_more(one_out_of(LETTER, "_"))) * "}"

const parse_rules = Dict(
    "type"=>LITERAL_VALUE,
    "porosity"=>NUMERICAL_VALUE,
    "porosity_dup"=>NUMERICAL_VALUE,
    "val"=>NUMERICAL_VALUE,
    "exposure_time"=>one_or_more(DIGIT) * maybe(' ') * "min",
    "exposure_time_dup"=>one_or_more(DIGIT) * maybe(' ') * "min",
    "cd_type"=>one_out_of("C", "D", "c", "d", "CD"),
    "U"=>NUMERICAL_VALUE * maybe("V"),
    "I"=>NUMERICAL_VALUE,
    "scan_rate"=>NUMERICAL_VALUE
)

const type_detection = Dict(
    "CV"  => CiclycVoltammetry,
    "C&D" => GalvanostaticChargeDischarge,
    "EIS" => ElectrochemicalImpedanceSpectroscopy
)

const name_contents = (
    separator = '_',
    type = 2,
    val = 3,
    cd_location = 4,
    replace_str = Dict(' '=>"", "min"=>"minute"),
    # functions = (I = filevalue, scan_rate = filevalue, porosity = (f,r,k)->foldervalue(f)),
    implicit_units = (I = u"A", scan_rate = u"mV/s", porosity = u"mA/cm^2", exposure_time = u"minute"),
)

function to_regex(spec_str, parse_rules)
    n = count("{", spec_str)
    i = 0
    has_prefix = !startswith(spec_str, "{")
    has_suffix = !endswith(spec_str, "}")
    for match in eachmatch(PARSE_FORMAT, spec_str)
        spec_str = replace(spec_str,
                           match.match=>(i == 0 && !has_prefix ? "\"" : "\" * ") *
                           string(capture(parse_rules[match.captures[1]],
                                          as=match.captures[1]))
                           * (i == n-1 && !has_suffix ? "" : "* \""))
        i += 1
    end
    if has_prefix
        spec_str = "\"" * spec_str
    end
    if !has_suffix
        spec_str * "\""
    end

    return eval(Meta.parse(spec_str))
end

function match_spec(spec_str, filename, parse_rules)
    re = to_regex(escape_string(spec_str), parse_rules)
    match(re, filename)
end

"""
    filetype(filename, spec_str, parse_rules, type_rules)

Filetype detection
"""
function filetype(filename, spec_str, parse_rules, type_rules)
    if occursin("{type}", spec_str)
        m = match_spec(spec_str, filename, parse_rules)
        T = type_rules[m[:type]]
    elseif occursin("{cd_type}", spec_str)
        T = GalvanostaticChargeDischarge
    else
        @error "Unknown file type for $filename"
        T = nothing
    end

    return T
end

function parse_quantity(match, key, rules, T=Float64)
    # if !haskey(match, key)
    #     return missing
    # end

    unit = getproperty(rules.implicit_units, key)
    value = match[key]

    if haskey(rules, :replace_str)
        for p in pairs(rules.replace_str)
            value = replace(value, p)
        end
    end

    if !isnothing(unit)
        parse(T, value) * unit
    else
        uparse(value)
    end
end
