open Base
open Core
open Async

module Indicators = struct
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

  let run_tests () =
    printf ": %s\n" (test_sma () |> Bool.to_string);
    printf ": %s\n" (test_ema () |> Bool.to_string)
end
