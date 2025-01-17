open Nun_mod

(** Definition **)

type model =
  {
    var : (string * string) list ;
    mem : (string * (string list)) list ;
    app : (string list * decision_tree) option;
    dom : (string list * decision_tree) option
  }

and decision_tree =
  {
    cases: ((string * string) list * string) list;
    else_ : string;
  }

type tla_mod = VALID | UNKNOWN | TIMEOUT | REFUTED of model


(** Translation **)

val nun_mod_to_tla_mod : nun_mod -> tla_mod


(** Printer **)

val fmt_tla_mod : Format.formatter -> tla_mod -> unit

val print_tla_mod : string -> tla_mod -> unit

val tla_mod_to_string : tla_mod -> string
