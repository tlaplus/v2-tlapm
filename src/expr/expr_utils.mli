(** Some basic operations on the expression datastructures. *)
open Commons
open Expr_ds
open Expr_builtins

module Unpack : sig
  (** Extracts the formal parameter from an entry *)
  val fp_entry : entry -> formal_param_

  (** Extracts the module from an entry *)
  val mod_entry : entry -> mule_

  (** Extracts the operator declaration from an entry *)
  val opdecl_entry : entry -> op_decl_

  (** Extracts the operator definition from an entry *)
  val module_instance_entry : entry -> module_instance_

  (** Extracts the operator definition from an entry *)
  val user_defined_op_entry : entry -> user_defined_op_

  (** Extracts the operator definition from an entry *)
  val builtin_op_entry : entry -> builtin_op_

  (** Extracts the operator definition from an entry *)

  val theorem_def_entry : entry ->  theorem_def_

  (** Extracts the operator definition from an entry *)
  val assume_def_entry : entry -> assume_def_

  (** Extracts the theorem from an entry *)
  val thm_entry : entry -> theorem_

  (** Extracts the assume from an entry *)
  val assume_entry : entry -> assume_
end

(** Extracts a location from an expression *)
val location_of_expr : expr -> location

(** Extracts a location from an expression *)
val level_of_expr : expr -> level option

(** Extracts a location from an expression *)
val location_of_expr_or_op_arg : expr_or_op_arg -> location

(** Extracts a location from an expression *)
val level_of_expr_or_op_arg : expr_or_op_arg -> level option


(** Wraps an expression into an assume-prove with empty assumptions *)
val assume_prove_from_expr : bool -> expr -> assume_prove

(** gets the level of a node *)
val level_of_node : node -> level option
