using CSV
using DataFrames
using DelimitedFiles

export get_result, get_columns, save_summary

read_file_as_df(file_name) = CSV.File(file_name) |> DataFrame

function get_columns(file_name)
      df = read_file_as_df(file_name)
      return names(df)
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
function get_result(source; cols_of_info, cols_of_hw, total_points, max_score=15)

      info_cols = Dict(cols_of_info) |> collect |> (d -> sort(d, by=x -> x[1])) .|> a -> a[2]
      hw_cols = Dict(cols_of_hw) |> collect |> (d -> sort(d, by=x -> x[2])) .|> a -> a[2]
      try
            df =
                  read_file_as_df(source) |>
                  df ->
                        rename(df, cols_of_info..., cols_of_hw...) |>
                        df -> select(df, :username => (r -> parse.(Int, SubString.(r, 2, 10))) => :id,
                              info_cols..., hw_cols...) |>
                              df -> ifelse.(ismissing.(df), 0.0, df) |>
                                    df -> select(df, :id, info_cols..., :) |>
                                          df -> select(df, :, hw_cols => ((r...) -> sum(r)) => :total) |>
                                                df -> select(df, :, :total => (r -> min.(max_score, ceil.(max_score * r / (total_points)))) => :score) |>
                                                      df -> sort(df, [:section, :id])
            df
            # stacktrace(catch_backtrace())
      catch err
            println(err.message)
      end
end
# df[1,5:end]
# des = describe(df)

function save_summary(file_name::String, df::DataFrame)
      writedlm(file_name, Iterators.flatten(([names(df)], eachrow(df))), ',')
end
# 
