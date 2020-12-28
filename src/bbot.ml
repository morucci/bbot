open Core
open Base
open Async

let klines_req_to_report_entry (pair : string) (period : Report_t.period)
    (res : (Binance_t.kline list, string) Result.t) : Report_t.report_entry =
  res
  |> Result.bind ~f:(fun klines ->
         Ok
           ( klines
           |> List.map ~f:(fun kline -> kline |> Binance.to_kline_record)
           |> Binance.run_ta_analysys
           |> Report.klines_analysed_to_report_entry pair period 4 ))
  |> Result.map_error ~f:(fun err ->
         Report.make_err_report_entry pair period 4 err)
  |> function
  | Ok report_entry -> report_entry
  | Error report_entry -> report_entry

let get_klines_to_report_entry (pair : string) (period : Report_t.period) =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=" ^ pair ^ "&interval="
    ^ (period |> Report.period_to_string)
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:10.0
  >>= fun res -> res |> klines_req_to_report_entry pair period |> return

let get_pair_to_report_entries (pair : string) :
    Report_t.report_entry list Deferred.t =
  let d1 = get_klines_to_report_entry pair `ONE_H in
  let d2 = get_klines_to_report_entry pair `ONE_D in
  Deferred.all [ d1; d2 ]

let get_pairs_to_json_report filename =
  [ "BTCUSDT"; "ETHUSDT"; "BNBUSDT"; "XRPUSDT" ]
  |> List.map ~f:get_pair_to_report_entries
  |> Deferred.all
  >>= fun res ->
  res |> List.concat |> Report_j.string_of_report |> fun contents ->
  Writer.save filename ~fsync:true ~contents

let main () =
  let report_file = "/tmp/report.json" in
  get_pairs_to_json_report report_file >>| fun _ ->
  Reader.file_contents report_file >>| fun contents ->
  printf "%s"
    ( Report_j.report_of_string contents
    |> List.map ~f:(fun re -> re |> Report.report_entry_to_string)
    |> String.concat ~sep:"\n" )

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  main () |> ignore;
  never_returns (Scheduler.go ())
