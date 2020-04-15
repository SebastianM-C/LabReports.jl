module LabReports

using CSV
using Unitful
using DataFrames

export find_files, filevalues, foldervalue, files_with_val, common_values,

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

end # module
