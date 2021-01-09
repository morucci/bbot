open Core
open Base
open Async

module ReportEngine = struct
  let get_klines_to_report_entry (pair : string) (period : Report_t.period)
      (fetcher : (Ta.Kline.t list, string) Result.t Deferred.t)
      (tracker_url : string) : Report_t.report_entry Deferred.t =
    fetcher >>= fun res ->
    res
    |> Result.bind ~f:(fun klines ->
           Ok
             ( klines |> Ta.KAnalyser.run_ta_analysys
             |> Report.Generator.klines_a_to_report_entry tracker_url pair
                  period 4 ))
    |> Result.map_error ~f:(fun err ->
           Report.Generator.make_err_report_entry tracker_url pair period 4 err)
    |> (function
         | Ok report_entry -> report_entry | Error report_entry -> report_entry)
    |> return

  let get_pair_to_report_entries (fetcher : Provider.klines_fetcher_t)
      (tracker_url : string -> string) (pair : string) :
      Report_t.report_entry list Deferred.t =
    [ `ONE_H; `ONE_D ]
    |> List.map ~f:(fun period ->
           get_klines_to_report_entry pair period (fetcher period)
             (tracker_url pair))
    |> Deferred.all

  let get_pairs_to_json_report (filename : string)
      (tracker_int : Provider.fetcher_i) =
    tracker_int.pairs |> List.rev
    |> List.map ~f:(fun pair ->
           get_pair_to_report_entries (tracker_int.fetcher pair)
             tracker_int.tracker_url pair)
    |> Deferred.all
    >>= fun res ->
    res |> List.concat |> Report.Generator.make_report
    |> Report_j.string_of_report
    |> fun contents -> Writer.save filename ~fsync:true ~contents
end

module BBotEngine = struct
  let round (report_file : string) =
    ReportEngine.get_pairs_to_json_report report_file Binance.KFetcher.interface
    >>| fun _ ->
    Reader.file_contents report_file >>| fun contents ->
    print_endline
      ( (Report_j.report_of_string contents).report
      |> List.map ~f:(fun re ->
             re |> Report.Generator.Stringify.report_entry_to_string)
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
end

let () =
  (* Ta.IndicatorsTests.run_tests (); *)
  BBotEngine.scheduler "/tmp/report.json" 60.;
  never_returns (Scheduler.go ())
