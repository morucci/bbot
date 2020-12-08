open Core
open Base
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
              ("Timed out (" ^ Float.to_string timeout ^ "s) calling: " ^ url));
        choice (get url decoder ~interrupt:(Ivar.read interrupt)) (fun id -> id);
      ]
end

module Binance = struct
  type kline = {
    o_t : int;
    o_p : float;
    h_p : float;
    l_p : float;
    c_p : float;
    vol : float;
    c_t : int;
    trades : int;
  }

  let to_kline_record (kline : Binance_t.kline) : kline =
    kline |> function
    | o_t, o_p, h_p, l_p, c_p, vol, c_t, _, trades, _, _, _ ->
        {
          o_t;
          o_p = o_p |> Float.of_string;
          h_p = h_p |> Float.of_string;
          l_p = l_p |> Float.of_string;
          c_p = c_p |> Float.of_string;
          vol = vol |> Float.of_string;
          c_t;
          trades;
        }
end

module Tools = struct
  let slice (l : 'a list) i k =
    let r = List.drop l i |> List.rev in
    List.drop r ((l |> List.length) - k - 1) |> List.rev

  let float_list_to_str l =
    l |> List.map ~f:Float.to_string |> String.concat ~sep:","

  let int_list_to_float_list l = List.map ~f:Float.of_int l

  let list_equal (l : float list) (l' : float list) =
    List.zip_exn l l'
    |> List.map ~f:(fun (a, b) -> Float.( = ) a b)
    |> List.for_all ~f:(Bool.( = ) true)
end

module Indicators = struct
  let _sma series =
    series |> List.fold ~init:0. ~f:(fun acc e -> acc +. e) |> fun v ->
    Float.( / ) v (Float.of_int (List.length series))

  let sma period series =
    let rs = series |> List.rev in
    rs
    |> List.foldi ~init:[] ~f:(fun i acc _ ->
           let sr = period - 1 in
           if i + 1 + sr <= (rs |> List.length) then
             _sma (Tools.slice rs i (i + sr)) :: acc
           else acc)

  let _ema period (series : float list) =
    let k = 2.0 /. (Float.of_int period +. 1.) in
    let rev_series = List.rev series in
    let rec __ema series =
      match series with
      | [] -> 1.
      | t :: _ -> (k *. t) +. ((1. -. k) *. __ema (List.drop series 1))
    in
    __ema rev_series
end

module IndicatorsTests = struct
  let test_sma () : bool =
    (* https://goodcalculators.com/simple-moving-average-calculator/ *)
    printf "Test SMA ";
    let series =
      [ 2; 4; 6; 8; 12; 14; 16; 18; 20 ] |> Tools.int_list_to_float_list
    in
    let expected = [ 6.4; 8.8; 11.2; 13.6; 16. ] in
    let computed = Indicators.sma 5 series in
    printf "[%s], [%s]"
      (computed |> Tools.float_list_to_str)
      (expected |> Tools.float_list_to_str);
    Bool.( = ) (Tools.list_equal expected computed) true

  let test_ema () : bool =
    (* https://goodcalculators.com/exponential-moving-average-calculator/ *)
    printf "Test EMA ";
    let series =
      [ 2; 4; 6; 8; 12; 14; 16; 18; 20 ] |> Tools.int_list_to_float_list
    in
    (* let expected = [ 3.; 3.333; 4.222; 5.481; 7.654; 9.77; 11.846; 13.898 ] in *)
    let computed = Indicators._ema 2 series in
    printf "%f" computed;
    (* printf "[%s], [%s]"
         (computed |> Tools.float_list_to_str)
         (expected |> Tools.float_list_to_str);
       Bool.( = ) (Tools.list_equal expected computed) true *)
    true

  let run_tests () =
    printf ": %s\n" (test_sma () |> Bool.to_string);
    printf ": %s\n" (test_ema () |> Bool.to_string)
end

(* let () =
  let url =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m"
  in
  Api.get_with_timeout url Binance_j.klines_of_string ~timeout:5.0
  >>| (function
        | Ok jd -> jd |> Binance_j.string_of_klines |> printf "%s"
        | Error err -> printf "%s" err)
  |> ignore;
  never_returns (Scheduler.go ()) *)

let () =
  IndicatorsTests.run_tests ();
  never_returns (Scheduler.go ())
