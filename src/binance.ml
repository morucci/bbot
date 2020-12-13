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
