struct DataFile{T}
    filename::String
    savename::String
    units::Vector{String}
    legend_units::String
    idx::Int
end

function DataFile(filename::String, ext)
    filename = preprocess(filename)
    savename = joinpath(dirname(filename), basename(filename) * ext)

    idx = 1
    if occursin("CV", filename)
        units = [""]
        legend_units = "mV/s"
        idx = 2
        T = Val{:CV}
    elseif occursin("C&D", filename)
        units = [""]
        legend_units = "A"
        T = Val{Symbol("C&D")}
    elseif occursin("EIS", filename)
        units = [""]
        legend_units = "mA/cm^2"
        T = Val{:EIS}
    else
        units = [""]
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
