open Core
open Async

module Api = struct
  let query_uri url = Uri.of_string url

  let get url decoder ~interrupt =
    try_with (fun () ->
        Cohttp_async.Client.get ~interrupt (query_uri url) >>= fun (_, body) ->
        Cohttp_async.Body.to_string body >>| decoder)
    >>| function
    | Ok result -> Ok result
    | Error err -> Error ("Unexpected failure: " ^ Exn.to_string err)

  let get_with_timeout url decoder ~timeout =
    let interrupt = Ivar.create () in
    choose
      [
        choice
          (after (Time.Span.of_sec timeout))
          (fun () ->
            Ivar.fill interrupt ();
            Error
              ("Timed out (" ^ string_of_float timeout ^ "s) calling: " ^ url));
        choice (get url decoder ~interrupt:(Ivar.read interrupt)) (fun id -> id);
      ]
end

let () =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m"
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:5.0
  >>| (function
        | Ok jd -> jd |> Binance_j.string_of_klines |> printf "%s"
        | Error err -> printf "%s" err)
  |> ignore;
  never_returns (Scheduler.go ())
