open Simple_expr_ds
open Simple_expr_utils
open List

let find_entry unpack entries i =
  let elem = try
      assoc i entries
    with
    | Not_found ->
      failwith ("Could not find entry for reference " ^
                (string_of_int i) ^ "!")
  in
  unpack elem

let dereference_user_defined_op term_db = function
  | UOP d -> d
  | UOP_ref r ->
    let opd = find_entry unpack_opdef_entry term_db r in
    match opd with
    | O_user_defined_op (UOP op) -> op
    | _ -> failwith ("The id " ^ (string_of_int r) ^
                     " does refer to a user defined operator!")

let dereference_formal_param term_db = function
  | FP fp -> fp
  | FP_ref i ->
    find_entry unpack_fp_entry term_db i

let dereference_op_decl term_db = function
  | OPD opd -> opd
  | OPD_ref x ->
    find_entry unpack_opdecl_entry term_db x

let dereference_user_defined_op term_db = function
  | UOP d -> d
  | UOP_ref x ->
    match find_entry unpack_opdef_entry term_db x with
    | O_user_defined_op (UOP op) -> op
    | O_user_defined_op _ ->
      failwith "Self-reference in term db!"
    | _ ->
      let str = Printf.sprintf
          "The id %d does not refer to a user defined operator!" x
      in
      failwith str
