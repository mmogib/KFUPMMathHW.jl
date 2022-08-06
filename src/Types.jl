
export HW, HWFile, FileSource


struct HW
    index::Int
    label::Symbol
    type::Symbol
    maxscore::Int64
end


# @enum FileSource bb = 1 wa = 2
struct HWFile
    name::String
    type::String
    inputpath::String
    outputpath::String
    hw::Union{Nothing,Vector{HW}}
    content::Union{Nothing,DataFrame}
    summary::Union{Nothing,DataFrame}
end

HWFile(name::String, type::String) = HWFile(name, type, "", "", nothing, nothing, nothing)
HWFile(name::String, type::String, inputpath::String) = HWFile(name, type, inputpath, "", nothing, nothing, nothing)
HWFile(name::String, type::String, inputpath::String, outputpath::String) = HWFile(name, type, inputpath, outputpath, nothing, nothing, nothing)
HWFile(f::HWFile, hw::Vector{HW}) = HWFile(f.name, f.type, f.inputpath, f.outputpath, hw, nothing, nothing)
HWFile(f::HWFile, content::DataFrame) = HWFile(f.name, f.type, f.inputpath, f.outputpath, f.hw, content, nothing)
HWFile(f::HWFile, content::Union{Nothing,DataFrame}, summary::Union{Nothing,DataFrame}) = HWFile(f.name, f.type,
    f.inputpath, f.outputpath, f.hw, content, summary)
function Base.show(io::IO, f::HWFile)
    print(io, "File {\n\t name: $(f.name)  \n")
    print(io, "\t type: $(f.type)\n ")
    print(io, "\t input path: $(f.inputpath) \n ")
    print(io, "\t output path: $(f.outputpath) \n ")
    if !isnothing(f.content)
        print(io, "\t input content: $(nrow(f.content))\n ")
    end
    if !isnothing(f.summary)
        print(io, "\t output content: $(nrow(f.summary))\n ")
    end

    print(io, "\n}\n")
end