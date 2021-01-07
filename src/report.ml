open Base
open Core

module Generator = struct
  type t = Report_t.report

  module Stringify = struct
    let float_to_string f = sprintf "%.6f" f

    let period_to_string (period : Report_t.period) : string =
      period |> function `ONE_H -> "1h" | `ONE_D -> "1d"

    let gb_to_string (gb : Report_t.gb) : string =
      gb |> function `GOOD -> "GOOD" | `BAD -> "BAD"

    let cs_to_string (cs : Report_t.cs) : string =
      cs |> function
      | `UP cs -> "UP(" ^ (cs |> string_of_int) ^ ")"
      | `DOWN cs -> "DOWN(" ^ (cs |> string_of_int) ^ ")"

    let price_report_entries_to_string (depth : int)
        (pre : Report_t.price_report_entry) : string =
      "PRICE: "
      ^ String.concat ~sep:" "
          ( pre.periods
          |> List.mapi ~f:(fun i p ->
                 "[T-"
                 ^ (depth - i |> Int.to_string)
                 ^ ": " ^ (p |> float_to_string) ^ "]") )

    let macd_report_entry_to_string (depth : int)
        (mre : Report_t.macd_report_entry) : string =
      "MACD: "
      ^ String.concat ~sep:" "
          ( mre.periods
          |> List.mapi ~f:(fun i p ->
                 "[T-"
                 ^ (depth - i |> Int.to_string)
                 ^ ":" ^ " DIFF: "
                 ^ (Report_t.(p.diff) |> float_to_string)
                 ^ " L: "
                 ^ (Report_t.(p.macd_line) |> float_to_string)
                 ^ "]") )
      ^ " [" ^ (mre.cs |> cs_to_string) ^ "]" ^ " ["
      ^ (mre.momentum |> gb_to_string)
      ^ "]"

    let report_entry_to_string (re : Report_t.report_entry) : string =
      let head = re.pair ^ "/" ^ (re.period |> period_to_string) ^ ": " in
      match re.data with
      | `SUCCESS data ->
          let price_line =
            head ^ (data.price |> price_report_entries_to_string re.depth)
          in
          let macd_line =
            head ^ (data.macd |> macd_report_entry_to_string re.depth)
          in
          price_line ^ "\n" ^ macd_line
      | `ERROR err -> head ^ "An error occured: " ^ err
  end

  let macd_momentum_gb (klines_a : Ta.KAnalyser.t) : Report_t.gb =
    let last_macd = klines_a.macd.macd_line |> List.last_exn in
    let last_macd_diff = klines_a.macd_diff |> List.last_exn in
    if Float.( > ) last_macd 0. && Float.( > ) last_macd_diff 0. then `GOOD
    else `BAD

  let make_price_report_entry (depth : int) (klines_a : Ta.KAnalyser.t) :
      Report_t.price_report_entry =
    let s, n = Tools.get_bounces depth klines_a.klines in
    let last_klines = Tools.slice klines_a.klines s n in
    let prices = last_klines |> List.map ~f:(fun k -> Ta.Kline.(k.c_p)) in
    { periods = prices }

  let make_macd_report_entry (depth : int) (klines_a : Ta.KAnalyser.t) :
      Report_t.macd_report_entry =
    let s, n = Tools.get_bounces depth klines_a.klines in
    let last_macd = Tools.slice klines_a.macd.macd_line s n in
    let last_macd_diff = Tools.slice klines_a.macd_diff s n in
    let periods =
      List.map2_exn
        ~f:(fun diff macd_line -> Report_t.{ diff; macd_line })
        last_macd_diff last_macd
    in
    let cs =
      if Float.( >= ) (klines_a.macd_diff |> List.last_exn) 0. then
        `UP klines_a.macd_last_crossed_since
      else `DOWN klines_a.macd_last_crossed_since
    in
    let momentum = klines_a |> macd_momentum_gb in
    { periods; cs; momentum }

  let klines_a_to_report_entry (url : string) (pair : string)
      (period : Report_t.period) (depth : int) (klines_a : Ta.KAnalyser.t) :
      Report_t.report_entry =
    let data =
      Report_t.
        {
          price = klines_a |> make_price_report_entry depth;
          macd = klines_a |> make_macd_report_entry depth;
        }
    in
    Report_t.{ pair; period; depth; data = `SUCCESS data; url }

  let make_err_report_entry (url : string) (pair : string)
      (period : Report_t.period) (depth : int) (err : string) :
      Report_t.report_entry =
    { data = `ERROR err; pair; depth; period; url }

  let make_report (report : Report_t.report_entry list) : t =
    Report_t.{ report; epoch = Unix.time () }
end
