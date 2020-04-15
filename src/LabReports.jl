module LabReports

using CSV
using Unitful
using DataFrames

export find_files, filevalues, foldervalue, files_with_val, common_values, process_data, clear, OriginLab

include("base.jl")
include("io.jl")
include("unit_format.jl")
include("datafile.jl")
include("originlab.jl")
include("cv.jl")
include("cd.jl")
include("eis.jl")

end # module
