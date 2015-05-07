open Kaputt.Abbreviations
open Sany
open Sany_ds
open Sany_visitor
open Util

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
(** extracts all names *)
let name_visitor =
  object
    inherit [string list] visitor as super
    method name acc n = Util.add_missing acc [n]
  end

(** extracts all references *)
let ref_visitor =
  object
    inherit [int list] visitor as super
    method reference acc i = Util.add_missing acc [i]
  end

(** extracts dependencies between references *)
let dependency_visitor =
  object
    inherit [(int * int) list] visitor as super
    method entry acc { uid; reference } =
      let deps = ref_visitor#fmota [] reference in
      let pairs = List.map (fun x -> (uid, x)) deps in
      List.append acc pairs
  end

let internal_ds_names =
  object
    inherit [string list] Expr_visitor.visitor as super
    method name acc n = Util.add_missing acc [n]
  end

let test_sany filename () =
  let channel = open_in filename in
  let tree = exhandler (fun () -> import_xml channel) in
  close_in channel;
  let sany_names = List.sort compare (name_visitor#context [] tree) in
  (* Printf.printf "%s\n" (Util.mkString (fun x->x) sany_names); *)
  let builtins = Sany_builtin_extractor.extract_from_context tree in
  let etree = Sany_expr.convert_context tree ~builtins:builtins in
  let internal_names = List.sort compare (internal_ds_names#context [] etree) in
  (* Printf.printf "%s\n" (Util.mkString (fun x->x) internal_names); *)
  Assert.equal
    ~msg:("Names extracted from SANY XML are different " ^
            "from the ones in the internal data-structrues!")
    sany_names internal_names;
  tree

let test_xml filename =
  Test.make_assert_test
    ~title: ("xml parsing " ^ filename)
    (fun () -> ())
    (fun () ->
     Assert.no_raise ~msg:"Unexpected exception raised."
                     (fun () -> exhandler ( test_sany filename )  )
    )
    (fun () -> ())

let addpath = (fun (str : string) -> "test/resources/" ^ str ^ ".xml")

let files =
  List.map
    addpath [
      "empty";
      "UserDefOp";
      "lambda";
      "tuples";
      "Choose";
      "at" ;
      "expr" ;
      "instanceA" ;
      "Euclid";
      "exec";
      "priming_stephan";
      "withsubmodule";
      "OneBit";
      (* contains duplicates of multiple modules, takes long to load *)
      (*"pharos";  *)
    ]

let get_tests = List.map test_xml files
