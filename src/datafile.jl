struct DataFile{T}
    filename::String
    savename::String
    units::Vector{String}
    legend_units::String
    idx::Int
end

abstract type AbstractDataFile end

function datafile(filename::String, ext, delim, extra_rules)
    savename = joinpath(dirname(filename), basename(filename) * ext)
    units = extract_units(filename, delim)
    type_rules = merge(type_detection, extra_rules.type)
    name_rules = merge(name_contents, extra_rules.name)

    name = split(basename(filename), "_")
    type = name[name_rules.type]
    T = type_rules[type]

    T(filename, savename, units, name_rules)
end

function extract_units(filename, delim)
    firstline = readline(filename)
    parts = split(firstline, delim)
    units = String[]

    for p in parts
        m = match(r" \((?<unit>\w)\)", p)
        if !isnothing(m)
            push!(units, m[:unit])
        end
    end

    return units
end
