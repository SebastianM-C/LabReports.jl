using Documenter, LabReports

makedocs(;
    modules=[LabReports],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/SebastianM-C/LabReports.jl/blob/{commit}{path}#L{line}",
    sitename="LabReports.jl",
    authors="Sebastian Micluța-Câmpeanu <m.c.sebastian95@gmail.com>",
    assets=String[],
)
