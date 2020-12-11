open Base

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
