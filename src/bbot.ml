open Core
open Base
open Async

let klines_req_to_report_entry (url : string) (pair : string)
    (period : Report_t.period) (res : (Binance_t.kline list, string) Result.t) :
    Report_t.report_entry =
  res
  |> Result.bind ~f:(fun klines ->
         Ok
           ( klines
           |> List.map ~f:(fun kline -> kline |> Binance.to_kline_record)
           |> Binance.run_ta_analysys
           |> Report.klines_analysed_to_report_entry url pair period 4 ))
  |> Result.map_error ~f:(fun err ->
         Report.make_err_report_entry url pair period 4 err)
  |> function
  | Ok report_entry -> report_entry
  | Error report_entry -> report_entry

let get_klines_to_report_entry (pair : string) (period : Report_t.period) =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=" ^ pair ^ "&interval="
    ^ (period |> Report.period_to_string)
  in
  let tracker_pairurl =
    "https://www.binance.com/fr/trade/" ^ pair ^ "?layout=pro"
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:10.0
  >>= fun res ->
  res |> klines_req_to_report_entry tracker_pairurl pair period |> return

let get_pair_to_report_entries (pair : string) :
    Report_t.report_entry list Deferred.t =
  let d1 = get_klines_to_report_entry pair `ONE_H in
  let d2 = get_klines_to_report_entry pair `ONE_D in
  Deferred.all [ d1; d2 ]

let pair_list =
  [
    "BTCUSDT";
    "ETHUSDT";
    "LTCUSDT";
    "XRPUSDT";
    "DOTUSDT";
    "ADAUSDT";
    "BCHUSDT";
    "BNBUSDT";
    "LINKUSDT";
    "XLMUSDT";
    "EOSUSDT";
    "XMRUSDT";
    "THETAUSDT";
    "TRXUSDT";
    "XEMUSDT";
    "VETUSDT";
    "XTZUSDT";
    "UNIUSDT";
    "AAVEUSDT";
    "SNXUSDT";
  ]

let get_pairs_to_json_report filename =
  pair_list |> List.rev
  |> List.map ~f:get_pair_to_report_entries
  |> Deferred.all
  >>= fun res ->
  res |> List.concat |> Report.make_report |> Report_j.string_of_report
  |> fun contents -> Writer.save filename ~fsync:true ~contents

let round (report_file : string) =
  get_pairs_to_json_report report_file >>| fun _ ->
  Reader.file_contents report_file >>| fun contents ->
  print_endline
    ( (Report_j.report_of_string contents).report
    |> List.map ~f:(fun re -> re |> Report.report_entry_to_string)
    |> String.concat ~sep:"\n" )

let scheduler (report_file : string) (it_delay_secs : float) =
  let delta = 3. in
  let next_min_in =
    Float.( - ) it_delay_secs (Float.mod_float (Unix.time ()) it_delay_secs)
    +. delta
  in
  print_endline
    ("Waiting " ^ (next_min_in |> Float.to_int |> Int.to_string) ^ " secs ...");
  let start' = Unix.time () +. next_min_in in
  let start = Time.Span.of_sec start' |> Time.of_span_since_epoch in
  let stream = Clock.at_intervals ~start (Time.Span.of_sec it_delay_secs) in
  stream
  |> Stream.iter ~f:(fun _ ->
         print_endline
           ((Unix.time () |> Float.to_string) ^ ": Fetching and computing ...");
         round report_file |> ignore)

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  scheduler "/tmp/report.json" 60.;
  never_returns (Scheduler.go ())
