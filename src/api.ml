open Core
open Async

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
          Error ("Timed out (" ^ Float.to_string timeout ^ "s) calling: " ^ url));
      choice (get url decoder ~interrupt:(Ivar.read interrupt)) (fun id -> id);
    ]
