module LabReports

using CSV
using Unitful
using DataFrames
using NumericalIntegration

export find_files, filevalues, foldervalue, files_with_val, common_values,
    process_data, clear, OriginLab, series_with_common_value

include("io.jl")
include("describe.jl")
include("unit_format.jl")
include("datafile.jl")
include("originlab.jl")
# File types
include("filetypes/cv.jl")
include("filetypes/cd.jl")
include("filetypes/eis.jl")
# Analysis
include("analysis/aggregate.jl")
include("analysis/capacitance.jl")

end # module
