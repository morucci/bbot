(* Auto-generated from "binance.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type kline = Binance_t.kline

type klines = Binance_t.klines

val write_kline :
  Bi_outbuf.t -> kline -> unit
  (** Output a JSON value of type {!kline}. *)

val string_of_kline :
  ?len:int -> kline -> string
  (** Serialize a value of type {!kline}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_kline :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> kline
  (** Input JSON data of type {!kline}. *)

val kline_of_string :
  string -> kline
  (** Deserialize JSON data of type {!kline}. *)

val write_klines :
  Bi_outbuf.t -> klines -> unit
  (** Output a JSON value of type {!klines}. *)

val string_of_klines :
  ?len:int -> klines -> string
  (** Serialize a value of type {!klines}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_klines :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> klines
  (** Input JSON data of type {!klines}. *)

val klines_of_string :
  string -> klines
  (** Deserialize JSON data of type {!klines}. *)

