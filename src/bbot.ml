open Core
open Base
open Async

let run_ta_analysys (klines : Binance.kline list) : Binance.klines_analysed =
  let closed_prices = klines |> List.map ~f:(fun kr -> Binance.(kr.c_p)) in
  let sma10 = closed_prices |> Ta.Indicators.sma 10 in
  let ema10 = closed_prices |> Ta.Indicators.ema 10 in
  Binance.{ klines; sma10; ema10 }

let main () =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m"
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:5.0
  >>= fun res ->
  res
  |> Result.bind ~f:(fun klines ->
         Ok
           ( klines
           |> List.map ~f:(fun kline -> kline |> Binance.to_kline_record) ))
  |> return
  >>= fun res ->
  res
  |> Result.bind ~f:(fun krs ->
         Ok (krs |> List.map ~f:(fun kr -> Binance.(kr.c_p))))
  |> return
  >>| function
  | Ok flist ->
      printf "%s" (flist |> Ta.Indicators.ema 10 |> Tools.float_list_to_str)
  | Error err -> printf "Error: %s" err

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  main () |> ignore;
  never_returns (Scheduler.go ())
