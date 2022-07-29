using Documenter
using KFUPMMathHW

makedocs(
    sitename="KFUPMMathHW",
    format=Documenter.HTML(),
    modules=[KFUPMMathHW]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo="git@github.com:mmogib/KFUPMMathHW.jl.git"
)
