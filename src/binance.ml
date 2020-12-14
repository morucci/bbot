open Base
open Core

type kline = {
  o_t : int;
  o_p : float;
  h_p : float;
  l_p : float;
  c_p : float;
  vol : float;
  c_t : int;
  trades : int;
}

type klines_analysed = {
  klines : kline list;
  macd : Ta.Indicators.macd;
  macd_diff : float list;
  macd_last_crossed_since : int;
}

let to_kline_record (kline : Binance_t.kline) : kline =
  kline |> function
  | o_t, o_p, h_p, l_p, c_p, vol, c_t, _, trades, _, _, _ ->
      {
        o_t;
        o_p = o_p |> Float.of_string;
        h_p = h_p |> Float.of_string;
        l_p = l_p |> Float.of_string;
        c_p = c_p |> Float.of_string;
        vol = vol |> Float.of_string;
        c_t;
        trades;
      }

let compute_last_crossed_since (macd_diff : float list) : int =
  let rec compute l acc =
    match l with
    | [] -> []
    | [ _ ] -> [ 1 ]
    | x :: y :: xs ->
        if
          (Float.( > ) x 0. && Float.( < ) y 0.)
          || (Float.( < ) x 0. && Float.( > ) y 0.)
        then 1 :: compute (y :: xs) acc
        else 0 :: compute (y :: xs) acc
  in
  let zr = compute (macd_diff |> List.rev) [] in
  zr
  |> List.fold_until ~init:0
       ~f:(fun acc e -> if e = 1 then Stop acc else Continue (acc + 1))
       ~finish:(fun a -> a)

let run_ta_analysys (klines : kline list) : klines_analysed =
  let klines = klines |> List.drop_last in
  match klines with
  | None ->
      {
        klines = [];
        macd = { macd_line = []; signal_line = [] };
        macd_diff = [];
        macd_last_crossed_since = 0;
      }
  | Some klines ->
      let closed_prices = klines |> List.map ~f:(fun kr -> kr.c_p) in
      let macd = closed_prices |> Ta.Indicators.macd_12_26_9 in
      let macd_diff =
        List.map2_exn macd.macd_line macd.signal_line ~f:(fun ml sl -> ml -. sl)
      in
      let macd_last_crossed_since = macd_diff |> compute_last_crossed_since in
      { klines; macd; macd_diff; macd_last_crossed_since }

let float_to_string f = sprintf "%.2f" f

let klines_analysed_to_string pair period klines_analysed depth : string =
  let s = (klines_analysed.klines |> List.length) - depth in
  let n = klines_analysed.klines |> List.length in
  let last_klines = Tools.slice klines_analysed.klines s n in
  let last_macd_diff = Tools.slice klines_analysed.macd_diff s n in
  let str =
    last_klines
    |> List.foldi
         ~init:(pair ^ "/" ^ period ^ ":")
         ~f:(fun i init e ->
           init ^ " [T-"
           ^ (depth - i |> Int.to_string)
           ^ ":" ^ " P:" ^ (e.c_p |> float_to_string) ^ " MACD/DIFF: "
           ^ (List.nth_exn last_macd_diff i |> float_to_string)
           ^ "]")
  in
  str ^ " [MACD/CS:"
  ^ (klines_analysed.macd_diff |> compute_last_crossed_since |> Int.to_string)
  ^ "]"
