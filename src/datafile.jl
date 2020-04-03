struct DataFile{T}
    filename::String
    savename::String
    namemap::Dict{String,String}
    units::Vector{String}
    legend_units::String
    idx::Int
end

function DataFile(filename::String)
    filename = preprocess(filename)
    savename = joinpath(dirname(filename), prefix * basename(filename))

    idx = 1
    if occursin("CV", filename)
        namemap = Dict("WE(1).Current (A)"=>"Current (mA)",
                       "WE(1).Potential (V)"=>"Potential (V)")
        units = [""]
        legend_units = "mV/s"
        idx = 2
        T = Val{:CV}
    elseif occursin("C&D", filename)
        namemap = Dict("WE(1).Potential (V)"=>"Potential (V)",
                       "Time (s)"=>"Other Time (s)",
                       "Corrected time (s)"=>"Time (s)")
        units = [""]
        legend_units = "A"
        T = Val{Symbol("C&D")}
    elseif occursin("EIS", filename)
        namemap = Dict{String,String}()
        units = [""]
        legend_units = "mA/cm^2"
        T = Val{:EIS}
    else
        namemap = Dict{String,String}()
        units = [""]
        legend_units = ""
        T = Val{:unknown}
    end

    DataFile{T}(filename, savename, namemap, units, legend_units, idx)
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
