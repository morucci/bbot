open Core
open Async

module Api = struct
  (* let query_uri = Uri.of_string (String.concat [ "http://ip.jsontest.com/" ]) *)

  let query_uri =
    Uri.of_string
      (String.concat
         [ "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m" ])

  (* let decode json =
     printf "decoding";
     match Yojson.Safe.from_string json with
     | `Assoc [ kv ] -> Some (Yojson.Safe.to_string (snd kv))
     | _ -> None *)
  let decode json =
    printf "decoding";
    (* manage the exception  *)
    Binance_j.klines_of_string json

  let get ~interrupt =
    try_with (fun () ->
        Cohttp_async.Client.get ~interrupt query_uri >>= fun (_, body) ->
        Cohttp_async.Body.to_string body >>| fun str -> decode str)
    >>| function
    | Ok result -> Ok result
    | Error err -> Error ("Unexpected failure: " ^ Exn.to_string err)

  let get_with_timeout ~timeout =
    let interrupt = Ivar.create () in
    choose
      [
        choice (after timeout) (fun () ->
            Ivar.fill interrupt ();
            Error "Timed out");
        choice
          (get ~interrupt:(Ivar.read interrupt))
          (fun result ->
            let result' =
              match result with
              (* | Ok (Some ip) -> *)
              | Ok klines ->
                  printf "Done: %s" (Binance_j.string_of_klines klines);
                  Ok "ip"
              | Error err ->
                  printf "Error: %s" err;
                  Error "Unexpected failure"
            in
            result');
      ]
end

let () =
  Api.get_with_timeout ~timeout:(Time.Span.of_sec 2.) |> ignore;
  never_returns (Scheduler.go ())
