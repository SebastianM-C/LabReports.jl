module LabReports

using CSV
using Unitful
using DataFrames
using NumericalIntegration
using Interpolations
using OffsetArrays

export find_files, filevalue, filevalues, foldervalue, files_with_val, common_values,
    process_data, clear, OriginLab, series_with_common_value, compute_capacitances

include("datafile.jl")
include("io.jl")
include("describe.jl")
include("unit_format.jl")
include("originlab.jl")
# File types
include("filetypes/cv.jl")
include("filetypes/cd.jl")
include("filetypes/eis.jl")
# Analysis
include("analysis/aggregate.jl")
include("analysis/capacitance.jl")

end # module
