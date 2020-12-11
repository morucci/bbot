open Core
open Base
open Async

let main () =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m"
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:5.0
  >>| (function
        | Ok jd -> jd |> Binance_j.string_of_klines |> printf "%s"
        | Error err -> printf "%s" err)
  |> ignore

let () =
  Ta.IndicatorsTests.run_tests ();
  main ();
  never_returns (Scheduler.go ())
