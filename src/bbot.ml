open Core
open Base
open Async

let klines_req_to_analysed_str (pair : string) (interval : string)
    (res : (Binance_t.kline list, string) Result.t) =
  res
  |> Result.bind ~f:(fun klines ->
         Ok
           ( klines
           |> List.map ~f:(fun kline -> kline |> Binance.to_kline_record)
           |> Binance.run_ta_analysys
           |> Binance.klines_analysed_to_string pair interval 4 ))
  |> return

let get_klines_to_analysed_str (pair : string) (interval : string) =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=" ^ pair ^ "&interval="
    ^ interval
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:10.0
  >>= fun res -> res |> klines_req_to_analysed_str pair interval

let get_pair_to_analysed_str (pair : string) =
  let d1 = get_klines_to_analysed_str pair "1d" in
  let d2 = get_klines_to_analysed_str pair "1h" in
  Deferred.all [ d1; d2 ]
  >>| List.map ~f:(function
        | Ok str -> sprintf "%s" str
        | Error err -> sprintf "Error: %s" err)
  >>| String.concat ~sep:"\n"

let get_pairs_to_analysed_str () =
  [ "BTCUSDT"; "ETHUSDT"; "BNBUSDT"; "XRPUSDT" ]
  |> List.map ~f:get_pair_to_analysed_str
  |> Deferred.all
  >>| List.iter ~f:(fun str -> printf "%s\n\n" str)

let main () = get_pairs_to_analysed_str ()

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  main () |> ignore;
  never_returns (Scheduler.go ())
