open Kaputt.Abbreviations
open Sany

let exhandler f =
  try
    Printexc.record_backtrace true;
    let ret = f () in
    Printexc.record_backtrace false;
    ret
  with
    x ->
      Printf.printf "Exception: %s\n" (Printexc.to_string x);
      Printf.printf "Backtrace: %s\n\n" (Printexc.get_backtrace ());
      raise x
	

let test_xml filename =
  Test.make_simple_test
    ~title: ("xml parsing " ^ filename)
    (fun () ->
      Assert.no_raise ~msg:"Unexpected exception raised." (fun () ->
	let channel = open_in filename in
	let tree = exhandler (fun () -> import_xml channel)
	in
	close_in channel;
	tree
      )
    )

let addpath = (fun (str : string) -> "test/resources/" ^ str ^ ".xml")
let files = List.map addpath [
  "empty";
(* "UserDefOp"; not working yet *)
  (* "Euclid" ; not working yet *)
]
let get_tests = List.map test_xml files
