using CSV
using DataFrames
using DelimitedFiles

export get_result


function get_result(source, max_score;
      hw_max_score=15,
      cols_of_info=[1 => :last, 2 => :first, 3 => :username, 9 => :section, 10 => :mobile],
      cols_of_hw=[5 => :ch2, 6 => :ch3p1, 7 => :ch3p2, 8 => :ch4])

      info_cols = Dict(cols_of_info) |> collect |> (d -> sort(d, by=x -> x[1])) .|> a -> a[2]
      hw_cols = Dict(cols_of_hw) |> collect |> (d -> sort(d, by=x -> x[2])) .|> a -> a[2]
      try
            file = CSV.File(source)
            df =
                  DataFrame(file) |>
                  df ->
                        rename(df, cols_of_info..., cols_of_hw...) |>
                        df -> select(df, :username => (r -> parse.(Int, SubString.(r, 2, 10))) => :id,
                              info_cols..., hw_cols...) |>
                              df -> ifelse.(ismissing.(df), 0.0, df) |>
                                    df -> select(df, :id, info_cols..., :) |>
                                          df -> select(df, :, hw_cols => ((r...) -> sum(r)) => :total) |>
                                                df -> select(df, :, :total => (r -> min.(hw_max_score, ceil.(hw_max_score * r / (max_score)))) => :score) |>
                                                      df -> sort(df, [:section, :id])
            df
      catch err
            println("ERROR: ", err.msg)
            # stacktrace(catch_backtrace())
      end
end
# df[1,5:end]
# des = describe(df)

# writedlm("t212math101hw.csv", Iterators.flatten(([names(udf)], eachrow(udf))), ',')
