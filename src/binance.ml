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
  macd_12_26_9 : Ta.Indicators.macd;
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

let float_to_string f = sprintf "%.2f" f

let klines_analysed_to_string pair period klines_analysed depth : string =
  let s = (klines_analysed.klines |> List.length) - depth in
  let n = klines_analysed.klines |> List.length in
  let last_klines = Tools.slice klines_analysed.klines s n in
  let last_macd_12_26_9_macd_line =
    Tools.slice klines_analysed.macd_12_26_9.macd_line s n
  in
  let last_macd_12_26_9_signal_line =
    Tools.slice klines_analysed.macd_12_26_9.signal_line s n
  in
  last_klines
  |> List.foldi
       ~init:(pair ^ "/" ^ period ^ ":")
       ~f:(fun i init e ->
         init ^ " T-"
         ^ (depth - i - 1 |> Int.to_string)
         ^ ":" ^ " P:" ^ (e.c_p |> float_to_string) ^ " MACD/L: "
         ^ (List.nth_exn last_macd_12_26_9_macd_line i |> float_to_string)
         ^ " MACD/T: "
         ^ (List.nth_exn last_macd_12_26_9_signal_line i |> float_to_string))
