(* Auto-generated from "report.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type price_report_entry = Report_t.price_report_entry = {
  periods: float list
}

type macd_entry = Report_t.macd_entry = { diff: float; macd_line: float }

type gb = Report_t.gb

type macd_report_entry = Report_t.macd_report_entry = {
  periods: macd_entry list;
  cs: int;
  momentum: gb
}

type x_report_entry = Report_t.x_report_entry = {
  price: price_report_entry;
  macd: macd_report_entry
}

type x_report_entry_se = Report_t.x_report_entry_se

type period = Report_t.period

type report_entry = Report_t.report_entry = {
  data: x_report_entry_se;
  pair: string;
  url: string;
  depth: int;
  period: period
}

type report = Report_t.report = { report: report_entry list; epoch: float }

val write_price_report_entry :
  Bi_outbuf.t -> price_report_entry -> unit
  (** Output a JSON value of type {!price_report_entry}. *)

val string_of_price_report_entry :
  ?len:int -> price_report_entry -> string
  (** Serialize a value of type {!price_report_entry}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_price_report_entry :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> price_report_entry
  (** Input JSON data of type {!price_report_entry}. *)

val price_report_entry_of_string :
  string -> price_report_entry
  (** Deserialize JSON data of type {!price_report_entry}. *)

val write_macd_entry :
  Bi_outbuf.t -> macd_entry -> unit
  (** Output a JSON value of type {!macd_entry}. *)

val string_of_macd_entry :
  ?len:int -> macd_entry -> string
  (** Serialize a value of type {!macd_entry}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_macd_entry :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> macd_entry
  (** Input JSON data of type {!macd_entry}. *)

val macd_entry_of_string :
  string -> macd_entry
  (** Deserialize JSON data of type {!macd_entry}. *)

val write_gb :
  Bi_outbuf.t -> gb -> unit
  (** Output a JSON value of type {!gb}. *)

val string_of_gb :
  ?len:int -> gb -> string
  (** Serialize a value of type {!gb}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_gb :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> gb
  (** Input JSON data of type {!gb}. *)

val gb_of_string :
  string -> gb
  (** Deserialize JSON data of type {!gb}. *)

val write_macd_report_entry :
  Bi_outbuf.t -> macd_report_entry -> unit
  (** Output a JSON value of type {!macd_report_entry}. *)

val string_of_macd_report_entry :
  ?len:int -> macd_report_entry -> string
  (** Serialize a value of type {!macd_report_entry}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_macd_report_entry :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> macd_report_entry
  (** Input JSON data of type {!macd_report_entry}. *)

val macd_report_entry_of_string :
  string -> macd_report_entry
  (** Deserialize JSON data of type {!macd_report_entry}. *)

val write_x_report_entry :
  Bi_outbuf.t -> x_report_entry -> unit
  (** Output a JSON value of type {!x_report_entry}. *)

val string_of_x_report_entry :
  ?len:int -> x_report_entry -> string
  (** Serialize a value of type {!x_report_entry}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_x_report_entry :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> x_report_entry
  (** Input JSON data of type {!x_report_entry}. *)

val x_report_entry_of_string :
  string -> x_report_entry
  (** Deserialize JSON data of type {!x_report_entry}. *)

val write_x_report_entry_se :
  Bi_outbuf.t -> x_report_entry_se -> unit
  (** Output a JSON value of type {!x_report_entry_se}. *)

val string_of_x_report_entry_se :
  ?len:int -> x_report_entry_se -> string
  (** Serialize a value of type {!x_report_entry_se}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_x_report_entry_se :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> x_report_entry_se
  (** Input JSON data of type {!x_report_entry_se}. *)

val x_report_entry_se_of_string :
  string -> x_report_entry_se
  (** Deserialize JSON data of type {!x_report_entry_se}. *)

val write_period :
  Bi_outbuf.t -> period -> unit
  (** Output a JSON value of type {!period}. *)

val string_of_period :
  ?len:int -> period -> string
  (** Serialize a value of type {!period}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_period :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> period
  (** Input JSON data of type {!period}. *)

val period_of_string :
  string -> period
  (** Deserialize JSON data of type {!period}. *)

val write_report_entry :
  Bi_outbuf.t -> report_entry -> unit
  (** Output a JSON value of type {!report_entry}. *)

val string_of_report_entry :
  ?len:int -> report_entry -> string
  (** Serialize a value of type {!report_entry}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_report_entry :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> report_entry
  (** Input JSON data of type {!report_entry}. *)

val report_entry_of_string :
  string -> report_entry
  (** Deserialize JSON data of type {!report_entry}. *)

val write_report :
  Bi_outbuf.t -> report -> unit
  (** Output a JSON value of type {!report}. *)

val string_of_report :
  ?len:int -> report -> string
  (** Serialize a value of type {!report}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_report :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> report
  (** Input JSON data of type {!report}. *)

val report_of_string :
  string -> report
  (** Deserialize JSON data of type {!report}. *)

