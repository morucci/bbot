open Core
open Base
open Async

let klines_req_to_report_entry (pair : string) (period : Report_t.period)
    (res : (Binance_t.kline list, string) Result.t) =
  res
  |> Result.bind ~f:(fun klines ->
         Ok
           ( klines
           |> List.map ~f:(fun kline -> kline |> Binance.to_kline_record)
           |> Binance.run_ta_analysys
           |> Report.klines_analysed_to_report_entry pair period 4 ))
  |> Result.map_error ~f:(fun err ->
         Report.make_err_report_entry pair period 4 err)
  |> return

let get_klines_to_report_entry (pair : string) (period : Report_t.period) =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=" ^ pair ^ "&interval="
    ^ (period |> Report.period_to_string)
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:10.0
  >>= fun res -> res |> klines_req_to_report_entry pair period

let get_pair_to_analysed_str (pair : string) =
  let d1 = get_klines_to_report_entry pair `ONE_H in
  let d2 = get_klines_to_report_entry pair `ONE_D in
  Deferred.all [ d1; d2 ]
  >>| List.map ~f:(function
        | Ok report_entry -> report_entry |> Report.report_entry_to_string
        | Error report_entry -> report_entry |> Report.report_entry_to_string)
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
