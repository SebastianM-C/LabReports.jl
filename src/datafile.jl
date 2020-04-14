struct DataFile{T}
    filename::String
    savename::String
    units::Vector{String}
    legend_units::String
    idx::Int
end

function DataFile(filename::String, ext, delim)
    filename = preprocess(filename)
    savename = joinpath(dirname(filename), basename(filename) * ext)
    units = extract_units(filename, delim)

    idx = 1
    if occursin("CV", filename)
        legend_units = "mV/s"
        idx = 2
        T = Val{:CV}
    elseif occursin("C&D", filename)
        legend_units = "A"
        T = Val{Symbol("C&D")}
    elseif occursin("EIS", filename)
        legend_units = "mA/cm^2"
        T = Val{:EIS}
    else
        legend_units = ""
        T = Val{:unknown}
    end

    DataFile{T}(filename, savename, units, legend_units, idx)
end

function preprocess(filename)
    if occursin("C&D", filename)
        if !endswith(filename, "_C") && !endswith(filename, "_D")
            new_filename = filename * "_D"
            mv(filename, new_filename)
            @info "Renamed $filename to $new_filename"
            filename = new_filename
        end
    end

    return filename
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
