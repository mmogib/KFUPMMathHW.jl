using CSV
using DataFrames
using DelimitedFiles

include("Types.jl")

export get_result, get_columns, save_summary, get_content, students_in_bb_not_in_wa, students_in_wa_not_in_bb, students_in_both

read_file_as_df(file_name) = CSV.File(file_name) |> DataFrame

function get_columns(file::HWFile)
      if !isnothing(file.content)
            names(file.content)
      end
      content = read_file_as_df(file.inputpath)

      return names(content)
end

function get_columns(df::DataFrame)
      return names(df)
end


function get_columns(file_name)
      df = read_file_as_df(file_name)
      return names(df)
end


function parse_it(T::Type, x; default_value=-1)
      if ismissing(x)
            return default_value
      end

      if typeof(x) == T
            return x

      else
            v = tryparse(T, x)
            isnothing(v) ? default_value : v
      end
end

"""
      get_result(
            source;
            cols_of_info,
            cols_of_hw,
            max_score=15
      )

Read CSV file from `source`  and a DataFrame .

# Arguments
- `source::String`: The source file name.
- `cols_of_info::Dictionary`: The order and names of the columns of student info.
- `cols_of_hw::Dictionary`: The order and names of the columns of homework to be summerized.
- `total_points::Integer`: The total points of the homework.
- `max_score::Integer=15`: The maximum score of the homework according to the grading policy.

# Examples
```julia-repl
julia> math102_file = joinpath("../t213/source/","math102.csv")
"../t213/source/math102.csv"

julia> math102_df = get_result(math102_file,
      cols_of_info=[1=>:last,2=>:first,3=>:username,12=>:section,13=>:mobile],
      cols_of_hw=[6=>:ch6,8=>:ch11,9=>:ch8,10=>:ch5,11=>:ch7],
      total_points,
      max_score=15
      )
```
"""
function get_result(source::String;
      cols_of_info::Vector{Pair{Int64,Symbol}},
      cols_of_hw::Vector{Pair{Int64,Symbol}},
      total_points::Int64, max_score=15, order_cols=[:section, :id])

      info_cols = Dict(cols_of_info) |> collect |> (d -> sort(d, by=x -> x[1])) .|> a -> a[2]
      hw_cols = Dict(cols_of_hw) |> collect |> (d -> sort(d, by=x -> x[2])) .|> a -> a[2]
      try
            df =
                  read_file_as_df(source) |>
                  df ->
                        rename(df, cols_of_info..., cols_of_hw...) |>
                        df -> select(df, :username => (r -> parse_it.(Int, SubString.(r, 2, 10))) => :id,
                              info_cols..., hw_cols...) |>
                              df -> map(fld -> transform!(df, fld => (r -> parse_it.(Float64, r, default_value=0.0)) => fld), hw_cols) |>
                                    dfs -> dfs[end] |>
                                           df -> ifelse.(ismissing.(df), 0, df) |>
                                                 df -> select(df, :id, info_cols..., hw_cols...) |>
                                                       df -> select(df, :, hw_cols => ((r...) -> sum(r)) => :total) |>
                                                             df -> select(df, :, :total => (r -> min.(max_score, ceil.(max_score * r / (total_points)))) => :score) |>
                                                                   df -> sort(df, order_cols)
            df
            # stacktrace(catch_backtrace())
      catch err
            println("Error: ", err)
            # stacktrace(catch_backtrace())
      end
end


map_it(h::Array{HW,1}) = map(r -> r.index => r.label, h)

function get_result(source::String, hw::Array{HW,1}; max_score=15, order_cols=[:section, :id])
      info = filter(r -> r.type == :info, hw)
      homework = filter(r -> r.type == :hw, hw)
      cols_of_info = info |> map_it |> collect
      cols_of_hw = homework |> map_it |> collect
      total_points = sum(r -> r.maxscore, homework)
      cols_of_info, cols_of_hw, total_points, max_score, order_cols
      get_result(source; cols_of_info, cols_of_hw, total_points, max_score, order_cols)
end

function get_result(f::HWFile, hw::Array{HW,1}; max_score=15, order_cols=[:section, :id])
      info = filter(r -> r.type == :info, hw)
      homework = filter(r -> r.type == :hw, hw)
      cols_of_info = info |> map_it |> collect
      cols_of_hw = homework |> map_it |> collect
      total_points = sum(r -> r.maxscore, homework)
      cols_of_info, cols_of_hw, total_points, max_score, order_cols
      source = f.inputpath
      summary = get_result(source; cols_of_info, cols_of_hw, total_points, max_score, order_cols)

      HWFile(f, f.content, summary)
end

function get_result(f::HWFile, save::Bool; max_score=15, order_cols=[:section, :id])
      if save
            file = get_result(f::HWFile, f.hw; max_score, order_cols)
            save_summary(file.outputpath, file.summary)
            file
      else
            get_result(f::HWFile, f.hw; max_score, order_cols)
      end
end

function get_content(file::HWFile)
      source = file.inputpath
      content = read_file_as_df(source)
      HWFile(file, content)
end

function save_summary(file_name::String, df::DataFrame)
      writedlm(file_name, Iterators.flatten(([names(df)], eachrow(df))), ',')
end
# 

students_in_bb_not_in_wa(; bbdf::DataFrame, wadf::DataFrame) = antijoin(bbdf, wadf, on=:id)
students_in_wa_not_in_bb(; bbdf::DataFrame, wadf::DataFrame) = antijoin(wadf, bbdf, on=:id)
students_in_both(; bbdf::DataFrame, wadf::DataFrame) = innerjoin(wadf, bbdf, on=:id, makeunique=true) |> df -> select(df, :id, :score, :score_1)