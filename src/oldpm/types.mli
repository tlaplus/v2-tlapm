(*
 * Copyright (C) 2011  INRIA and Microsoft Corporation
 *)

type obligation = string

type reason =
  | False
  | Timeout
  | Cantwork of string
;;
type status_type_aux6 =
  | RSucc
  | RFail of reason option
  | RInt
;;
type status_type6 =
  | Triv
  | NTriv of status_type_aux6 * Method.t
;;

type package = {
  final_form   : obligation;
  (*  print_form   : Proof.T.obligation; *)
  log          : string list;
  proof        : string;
  results      : status_type6 list;
};;
