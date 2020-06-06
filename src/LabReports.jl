module LabReports

using CSV
using Unitful
using DataFrames
using NumericalIntegration
using Interpolations
using OffsetArrays
using Parameters

export find_files, filevalue, filevalues, foldervalue, filetype, files_with_val,
    common_values, process_data, clear, OriginLab, results, series_with_common_value,
    compute_capacitances, CSetup, CiclycVoltammetry, GalvanostaticChargeDischarge,
    ElectrochemicalImpedanceSpectroscopy, groupby

include("datafile.jl")
include("io.jl")
include("unit_format.jl")
include("originlab.jl")
# File types
include("filetypes/cv.jl")
include("filetypes/cd.jl")
include("filetypes/eis.jl")

include("describe.jl")
# Analysis
include("analysis/aggregate.jl")
include("analysis/area.jl")
include("analysis/cd.jl")
include("analysis/cv.jl")
include("analysis/capacitance.jl")

end # module
