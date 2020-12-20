open Base
open Core

type gb = GOOD | BAD

type price_report_entry = { periods : float list }

type macd_entry = { diff : float; macd_line : float }

type macd_report_entry = { periods : macd_entry list; cs : int; momentum : gb }

type x_report_entry = { price : price_report_entry; macd : macd_report_entry }

type period = ONE_H | ONE_D

type report_entry = {
  data : x_report_entry;
  pair : string;
  depth : int;
  period : period;
}

type report = report_entry list

let float_to_string f = sprintf "%.6f" f

let period_to_string (period : period) : string =
  period |> function ONE_H -> "1h" | ONE_D -> "1d"

let gb_to_string (gb : gb) : string =
  gb |> function GOOD -> "GOOD" | BAD -> "BAD"

let get_bounces (depth : int) (klines_a : Binance.klines_analysed) : int * int =
  let s = (klines_a.klines |> List.length) - depth in
  let n = klines_a.klines |> List.length in
  (s, n)

let macd_momentum_gb (klines_a : Binance.klines_analysed) : gb =
  let last_macd = klines_a.macd.macd_line |> List.last_exn in
  let last_macd_diff = klines_a.macd_diff |> List.last_exn in
  if Float.( > ) last_macd 0. && Float.( > ) last_macd_diff 0. then GOOD
  else BAD

let make_price_report_entry (depth : int) (klines_a : Binance.klines_analysed) :
    price_report_entry =
  let s, n = get_bounces depth klines_a in
  let last_klines = Tools.slice klines_a.klines s n in
  let prices = last_klines |> List.map ~f:(fun k -> Binance.(k.c_p)) in
  { periods = prices }

let price_report_entries_to_string (depth : int) (pre : price_report_entry) :
    string =
  "PRICE: "
  ^ String.concat ~sep:" "
      ( pre.periods
      |> List.mapi ~f:(fun i p ->
             "[T-"
             ^ (depth - i |> Int.to_string)
             ^ ": " ^ (p |> float_to_string) ^ "]") )

let make_macd_report_entry (depth : int) (klines_a : Binance.klines_analysed) :
    macd_report_entry =
  let s, n = get_bounces depth klines_a in
  let last_macd = Tools.slice klines_a.macd.macd_line s n in
  let last_macd_diff = Tools.slice klines_a.macd_diff s n in
  let periods =
    List.map2_exn
      ~f:(fun diff macd_line -> { diff; macd_line })
      last_macd_diff last_macd
  in
  let cs = klines_a.macd_diff |> Binance.compute_last_crossed_since in
  let momentum = klines_a |> macd_momentum_gb in
  { periods; cs; momentum }

let macd_report_entry_to_string (depth : int) (mre : macd_report_entry) : string
    =
  "MACD: "
  ^ String.concat ~sep:" "
      ( mre.periods
      |> List.mapi ~f:(fun i p ->
             "[T-"
             ^ (depth - i |> Int.to_string)
             ^ ":" ^ " DIFF: "
             ^ (p.diff |> float_to_string)
             ^ " L: "
             ^ (p.macd_line |> float_to_string)
             ^ "]") )
  ^ " [" ^ (mre.cs |> Int.to_string) ^ "]" ^ " ["
  ^ (mre.momentum |> gb_to_string)
  ^ "]"

let klines_analysed_to_report_entry (pair : string) (period : period)
    (depth : int) (klines_a : Binance.klines_analysed) : report_entry =
  let data =
    {
      price = klines_a |> make_price_report_entry depth;
      macd = klines_a |> make_macd_report_entry depth;
    }
  in
  { pair; period; depth; data }

let report_entry_to_string (re : report_entry) : string =
  let head = re.pair ^ "/" ^ (re.period |> period_to_string) ^ ": " in
  let price_line =
    head ^ (re.data.price |> price_report_entries_to_string re.depth)
  in
  let macd_line =
    head ^ (re.data.macd |> macd_report_entry_to_string re.depth)
  in
  price_line ^ "\n" ^ macd_line

let report_to_string (report : report) : string =
  String.concat ~sep:"\n\n"
    (report |> List.map ~f:(fun re -> re |> report_entry_to_string))
