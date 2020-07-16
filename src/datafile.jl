struct DataFile{T}
    filename::String
    savename::String
    units::Vector{String}
    legend_units::String
    idx::Int
end

abstract type AbstractDataFile end

function datafile(filename::String, ext, delim, extra_rules)
    if !endswith(filename, ext)
        savename = joinpath(dirname(filename), basename(filename) * ext)
        units = extract_units(filename, delim)
    else
        savename = filename
        units = extract_units(filename)
    end
    if hasproperty(extra_rules, :type)
        type_rules = merge(type_detection, extra_rules.type)
    else
        type_rules = type_detection
    end
    if hasproperty(extra_rules, :name)
        name_rules = merge(name_contents, extra_rules.name)
    else
        name_rules = name_contents
    end
    if hasproperty(extra_rules, :functions)
        name_rules = @set name_rules.functions = merge(name_contents.functions, extra_rules.functions)
    end
    if hasproperty(extra_rules, :units)
        name_rules = @set name_rules.implicit_units = merge(name_contents.implicit_units, extra_rules.units)
    end
    if hasproperty(extra_rules, :replace)
        name_rules = @set name_rules.replace_str = merge(name_contents.replace_str, extra_rules.replace)
    end

    name = split(basename(filename), name_rules.separator)
    type = name[name_rules.type]
    T = type_rules[type]

    T(filename, savename, units, name_rules)
end

function extract_units(filename, delim)
    firstline = readline(filename)
    parts = split(firstline, delim)
    units = Unitful.Units[]

    for p in parts
        m = match(r"(?<name>^.*) (?<unit>(.*))", p)
        if !isnothing(m)
            push!(units, uparse(m[:unit]))
        else
            push!(units, NoUnits)
        end
    end

    return units
end

function extract_units(filename)
    secondline = ""
    open(filename, "r") do io
        readline(io)
        secondline = readline(io)
    end

    units = Unitful.Units[]
    secondline = from_origin(secondline)
    parts = split(secondline, ";")

    for p in parts
        if !isempty(p)
            push!(units, uparse(p))
        else
            push!(units, NoUnits)
        end
    end

    return units
end
