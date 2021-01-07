open Base
open Core
open Async

module Indicators = struct
  type macd = { macd_line : float list; signal_line : float list }

  let sma period series =
    let _sma series =
      series |> List.fold ~init:0. ~f:(fun acc e -> acc +. e) |> fun v ->
      Float.( / ) v (Float.of_int (List.length series))
    in
    let rs = series |> List.rev in
    rs
    |> List.foldi ~init:[] ~f:(fun i acc _ ->
           _sma (Tools.slice rs i (i + period - 1)) :: acc)

  let rec _ema period (series : float list) =
    let alpha = 2.0 /. (Float.of_int period +. 1.) in
    match series with
    | [] -> 0.
    | [ p ] -> p
    | p :: xs -> (alpha *. p) +. ((1. -. alpha) *. _ema period xs)

  let ema period series =
    let rs = series |> List.rev in
    rs
    |> List.foldi ~init:[] ~f:(fun i acc _ ->
           _ema period (Tools.slice rs i (List.length series)) :: acc)

  let macd_12_26_9 series =
    let ema_12 = ema 12 series in
    let ema_26 = ema 26 series in
    (* macd_line above 0 tells a good momentum *)
    let macd_line = List.map2_exn ema_12 ema_26 ~f:(fun s l -> s -. l) in
    (* a signal line that cross over the macd_line is a buy sigal *)
    let signal_line = ema 9 macd_line in
    { macd_line; signal_line }
end

module IndicatorsTests = struct
  let test title func expected : bool =
    printf "%s: " title;
    let computed = func () in
    printf "[%s], [%s]"
      (computed |> Tools.float_list_to_str)
      (expected |> Tools.float_list_to_str);
    Bool.( = ) (Tools.list_equal expected computed) true

  let test_sma () : bool =
    (* https://goodcalculators.com/simple-moving-average-calculator/ *)
    let series =
      [ 2; 4; 6; 8; 12; 14; 16; 18; 20 ] |> Tools.int_list_to_float_list
    in
    let expected = [ 2.0; 3.0; 5.0; 7.0; 10.0; 13.0; 15.0; 17.0; 19.0 ] in
    test "Test SMA" (fun () -> Indicators.sma 2 series) expected

  let test_ema () : bool =
    (* https://goodcalculators.com/exponential-moving-average-calculator/ *)
    let series =
      [ 2; 4; 6; 8; 12; 14; 16; 18; 20 ] |> Tools.int_list_to_float_list
    in
    let expected =
      [
        2.;
        3.333333333333333;
        5.1111111111111107;
        7.0370370370370363;
        10.345679012345679;
        12.781893004115226;
        14.92729766803841;
        16.975765889346135;
        18.991921963115377;
      ]
    in
    test "Test EMA" (fun () -> Indicators.ema 2 series) expected

  let test_macd () : bool =
    (* https://goodcalculators.com/exponential-moving-average-calculator/ *)
    let series =
      [ 2; 4; 6; 8; 12; 14; 16; 18; 20 ] |> Tools.int_list_to_float_list
    in
    let expected_macd_line =
      [
        0.;
        0.15954415954415957;
        0.44226913742583296;
        0.81828136639380089;
        1.4226410173927064;
        2.0394738947577444;
        2.659049808422572;
        3.2737141304286608;
        3.8775256176935038;
      ]
    in
    test "Test MACD (macd line)"
      (fun () -> (Indicators.macd_12_26_9 series).macd_line)
      expected_macd_line

  let run_tests () =
    printf ": %s\n" (test_sma () |> Bool.to_string);
    printf ": %s\n" (test_ema () |> Bool.to_string);
    printf ": %s\n" (test_macd () |> Bool.to_string)
end

module Kline = struct
  type t = {
    o_t : int;
    o_p : float;
    h_p : float;
    l_p : float;
    c_p : float;
    vol : float;
    c_t : int;
    trades : int;
  }
end

module KAnalyser = struct
  type t = {
    klines : Kline.t list;
    macd : Indicators.macd;
    macd_diff : float list;
    macd_last_crossed_since : int;
  }

  let compute_last_crossed_since (macd_diff : float list) : int =
    let rec compute l acc =
      match l with
      | [] -> []
      | [ _ ] -> [ 1 ]
      | x :: y :: xs ->
          if
            (Float.( > ) x 0. && Float.( < ) y 0.)
            || (Float.( < ) x 0. && Float.( > ) y 0.)
          then 1 :: compute (y :: xs) acc
          else 0 :: compute (y :: xs) acc
    in
    let zr = compute (macd_diff |> List.rev) [] in
    zr
    |> List.fold_until ~init:0
         ~f:(fun acc e -> if e = 1 then Stop acc else Continue (acc + 1))
         ~finish:(fun a -> a)

  let run_ta_analysys (klines : Kline.t list) : t =
    let klines = klines |> List.drop_last in
    match klines with
    | None ->
        {
          klines = [];
          macd = { macd_line = []; signal_line = [] };
          macd_diff = [];
          macd_last_crossed_since = 0;
        }
    | Some klines ->
        let closed_prices = klines |> List.map ~f:(fun kr -> Kline.(kr.c_p)) in
        let macd = closed_prices |> Indicators.macd_12_26_9 in
        let macd_diff =
          List.map2_exn macd.macd_line macd.signal_line ~f:(fun ml sl ->
              ml -. sl)
        in
        let macd_last_crossed_since = macd_diff |> compute_last_crossed_since in
        { klines; macd; macd_diff; macd_last_crossed_since }
end
