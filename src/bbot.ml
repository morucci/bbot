open Core
open Base
open Async

let main () =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h"
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
         Ok
           (let krsa = krs |> Binance.run_ta_analysys in
            Binance.klines_analysed_to_string "BTCUSD" "1h" krsa 4))
  |> return
  >>| function
  | Ok str -> printf "%s\n" str
  | Error err -> printf "Error: %s" err

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  main () |> ignore;
  never_returns (Scheduler.go ())
