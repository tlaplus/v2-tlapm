open Commons
open Simple_expr_ds
open Simple_expr_visitor
open Simple_expr_utils
open Simple_expr_dereference
open Format
open Simple_expr_prover_parser
open Nunchaku_ast
       
type fc = statement list * simple_term_db * term * bool
	    
(* these are extractors for the accumulator type  *)
let sta     ( sta, _, _, _) = sta (* statement list *)
let tdb     ( _, tdb, _, _) = tdb (* term database *)
let ter     ( _, _, ter, _) = ter (* term accumulator *)
let top     ( _, _, _, top) = top (* flag : is_top_level *)
			     
let add_axiom l (sta, tdb, ter, top) =
  let x = axiom l in
  (x::sta, tdb, ter, top)

let add_decl v t (sta, tdb, ter, top) =
  let x = decl [] v t in
  (x::sta, tdb, ter, top)

let add_comm s (sta, tdb, ter, top) =
  let x = comm s in
  (x::sta, tdb, ter, top)

let add_include f (sta, tdb, ter, top) =
  let x = include_ f in
  (x::sta, tdb, ter, top)

let add_goal t (sta, tdb, ter, top) =
  let x = goal ( App ((Builtin `Not),[t])) in
  (x::sta, tdb, ter, top)
    
let set_term ter (sta, tdb, _, top) = (sta, tdb, ter, top)

let un_top (sta, tdb, ter, _) = (sta, tdb, ter, false)
		     
let acc_fold function_to_apply list_of_args acc =
   List.fold_right (fun arg_temp -> fun acc_temp -> function_to_apply acc_temp arg_temp) list_of_args acc

let acc_fold_plus function_to_apply list_of_args acc =
  List.fold_right (fun arg_temp -> fun (acc_temp,list_temp) ->
				   let acc_temp' = function_to_apply acc_temp arg_temp in
				   (acc_temp',(ter acc_temp')::list_temp)
		  ) list_of_args (acc,[])
		   
class formatter =
object(self)
  inherit [fc] visitor as super

  (* parts of expressions *)
  method location acc { column; line; filename } : 'a =
    add_comm "Crossed location" acc

  method level acc l : 'a =
    add_comm "Crossed level" acc

  (* non-recursive expressions *)
  method decimal acc0 { location; level; mantissa; exponent;  } =
    let value =
      (float_of_int mantissa) /. ( 10.0 ** (float_of_int exponent)) in
    let acc1 = set_term (Var (`Var (string_of_float value))) acc0 in
    (* add_comm ("Crossed decimal = "^(string_of_float value)) acc1 in *)
    acc1

  method numeral acc0 {location; level; value } =
    let acc1 = set_term (Var (`Var (string_of_int value))) acc0 in
    (* add_comm ("Crossed numeral = "^(string_of_int value)) acc1 *)
    acc1

  method strng acc {location; level; value} =
    add_comm ("Crossed string = "^value) acc

  method op_arg acc {location; level; argument } =
    self#operator acc argument

  (* recursive expressions *)
  method at acc {location; level; except; except_component} =
    add_comm "Crossed AT" acc
 
  method op_appl acc0 {location; level; operator; operands} =
    let acc1 = self#operator acc0 operator in

    let (acc2,t2) = List.fold_right
    		     (fun x -> fun (a,t) -> let a' = self#expr_or_op_arg a x in (a',(ter a')::t))
    		     operands (acc1,[]) in
    set_term (App ((ter acc1),t2)) acc2

    
  method lambda acc {level; arity; body; params} =
    add_comm "Crossed LAMBDA" acc
   
  method binder acc b =
   match b.bound_symbols with
    | []     -> let acc1 = self#operator acc b.operator in
		self#expr_or_op_arg acc1 b.operand
    | hd::tl -> let b2 = {location = b.location; level = b.level; operator = b.operator; operand = b.operand; bound_symbols = tl} in
		let acc0 = self#binder acc b2 in
		let t = ter acc0 in
		let acc1 = self#operator acc0 b.operator in
		let kind = ter acc1 in
		let acc2 = self#bound_symbol acc1 hd in
		let v = match ter acc2 with
		  | Var (`Var x) -> x
		  | _ -> failwith "variable identification"
		in
		let v' = (v,Some (var "u")) in
		let set = 
		  match hd with
    		  | B_unbounded_bound_symbol _ -> None
		  | B_bounded_bound_symbol bbs -> Some (ter (self#expr acc2 (bbs.domain))) (* TODO : transmettre acc *)
		in
		match kind with
		| Builtin `Forall -> set_term (Forall (v',set,t)) acc2
		| Builtin `Exists -> set_term (Exists (v',set,t)) acc2
		| _ -> failwith "binder not a quantifier"
		

    (* let acc1 = self#operator acc b.operator in *)
    (* let kind = ter acc1 in *)
    (* let acc2 = self#expr_or_op_arg acc1 b.operand in *)

    (* let rec unfold a bsl = *)
    (* match bsl with *)
    (* |  []  -> a *)
    (* | t::q -> let b2 = {location = b.location; level = b.level; operator = b.operator; operand = b.operand; bound_symbols = tl} in *)



    (*    match t with *)
    (* 	      | B_unbounded_bound_symbol _ -> unfold a q terml  *)
    (* 	      | B_bounded_bound_symbol bbs -> self#expr acc2 (bbs.domain) in *)
    (* 						  add_axiom [Mem (v,(ter acc21))] acc2	      | *)


   (* match b.bound_symbols with *)
   (*  | []     -> let acc1 = self#operator acc b.operator in *)
   (* 		self#expr_or_op_arg acc1 b.operand *)
   (*  | hd::tl -> let b2 = {location = b.location; level = b.level; operator = b.operator; operand = b.operand; bound_symbols = tl} in *)
   (* 		let acc0 = self#binder acc b2 in *)
   (* 		let t = ter acc0 in *)
   (* 		let acc1 = self#operator acc0 b.operator in *)
   (* 		let kind = ter acc1 in *)
   (* 		let acc2 = self#bound_symbol acc1 hd in *)
   (* 		let v = match ter acc2 with *)
   (* 		  | Var (`Var x) -> x *)
   (* 		  | _ -> failwith "variable identification" *)
   (* 		in *)
   (* 		let v' = (v,Some (var "u")) in *)
   (* 		match kind with *)
   (* 		| Builtin `Forall -> set_term (Forall (v',t)) acc2 *)
   (* 		| Builtin `Exists -> set_term (Exists (v',t)) acc2 *)
   (* 		| _ -> failwith "binder not a quantifier" *)

    
  (* TODO : HERE REMOVE MEM, match the bbs and kind to add finite sets *)

  method bounded_bound_symbol acc { params; tuple; domain; } =
      match params with
    | [] ->
       failwith "Trying to process empty tuple of bound symbols with domain!"
    | [param] ->
       (* let acc1 = match tuple with *)
       (* 	 | true -> add_to_string "<<" acc *)
       (* 	 | false -> acc *)
       (* in *)
       (* let acc2 = self#formal_param acc param in *)
       
       (* let acc3 = match tuple with *)
       (* 	 | true -> add_to_string "<<" acc2 *)
       (* 	 | false -> acc2 *)
       (* in *)
       (* let acc4 = add_to_string " \\in " acc3 in *)
       (* let acc5 = self#expr acc4 domain in *)
       self#formal_param acc param

    | _ ->
       (* fprintf (ppf acc) "<<"; *)
       (* let acc1 = ppf_fold_with self#formal_param acc params in *)
       (* fprintf (ppf acc1) ">> \\in "; *)
       (* let acc2 = self#expr acc domain in *)
       self#formal_param acc (List.hd params) (* TODO *)
    
  method unbounded_bound_symbol acc { param; tuple } =
    (* if tuple then fprintf (ppf acc) "<<"; *)
    (* let acc1 = self#formal_param acc param in *)
    (* if tuple then fprintf (ppf acc1) ">> "; *)
    self#formal_param acc param

  method formal_param acc fp =
    let { location; level; name; arity; } : simple_formal_param_ =
      dereference_formal_param (tdb acc) fp in
    set_term (var name) acc

  method op_decl acc0 opdec =
    let { location ; level ; name ; arity ; kind ; } =
      dereference_op_decl (tdb acc0) opdec in
    set_term (var name) acc0

  method op_def acc = function
     | O_builtin_op x      -> 
       self#builtin_op acc x
    | O_user_defined_op x ->
       let op = dereference_user_defined_op (tdb acc) x
       in
       add_comm op.name acc
	   
  method assume_prove acc { location; level; new_symbols; assumes;
                             prove; } =
    let acc0 = un_top acc in
    let acc1 = acc_fold self#new_symb new_symbols acc0 in (* declares new symbols with axioms for domain *)
    let acc2,l = acc_fold_plus self#assume_prove assumes acc1 in (* returns a list of assumes *)
    let acc3 = self#expr acc2 prove in
    let prove_expr = ter acc3 in
    let my_expr =
      match l with
      | [ ] -> prove_expr
      | [x] -> App (Builtin `Imply,[x;prove_expr])
      |  _  -> let assume_expr = App (Builtin `And,l) in
	       App (Builtin `Imply,[assume_expr;prove_expr])	
    in
    let acc4 = match top acc with
      | true ->	 add_goal my_expr acc3        (* if top level *)
      | false -> set_term my_expr acc3        (* else *)
    in
    acc4
      
  method new_symb acc0 { location; level; op_decl; set } =
    let od = dereference_op_decl (tdb acc0) op_decl in
    let new_decl = match od.kind with
      | NewConstant -> "u" (* default is constant "CONSTANT " *)
      | _ -> failwith "declared new symbol with a non-constant kind."
    in
    let acc1 = match set with
      | None -> acc0
      | Some e -> (* let acc01 = self#expr acc0 e in *)
		  add_comm "some set" acc0
		  (* TODO add axiom : mem x s *)
    in
    let acc2 = add_decl od.name (var new_decl) acc1 in
    acc2

  method let_in acc0 {location; level; body; op_defs } =
    failwith "remove -let_in- during preprocessing"

  (* TODO *)
  method label acc0 ({location; level; name; arity; body; params } : simple_label) =
    add_comm "LABEL" acc0

  method builtin_op acc { level; name; arity; params } =
    set_term (builtin (self#translate_builtin_name name)) acc

  method user_defined_op acc0 op =    
    acc0

  method expr acc x =
    let acc1 = match x with
    | E_binder  b -> self#binder  acc b
    | E_op_appl b -> self#op_appl acc b
    | E_numeral b -> self#numeral acc b
    | _ -> add_comm "Crossed unknown expression" acc
    in acc1

  method name acc x = acc

  method reference acc x = acc

  method translate_builtin_name = function
    (* | "$AngleAct"  as x -> failwith ("Unknown operator " ^ x ^"!") *)
    (* | "$BoundedChoose" -> "CHOOSE" *)
    | "$BoundedExists" -> `Exists
    | "$BoundedForall" -> `Forall
    (* | "$Case" -> "CASE" *)
    (* | "$CartesianProd" -> "\times" *)
    | "$ConjList" -> `And
    | "$DisjList" -> `Or
    (* | "$Except" -> "EXCEPT" *)
    (*    | "$FcnApply" as x -> failwith ("Unknown operator " ^ x ^"!") *)
    (*    | "$FcnConstructor"  as x -> failwith ("Unknown operator " ^ x ^"!") *)
    (* | "$IfThenElse" -> "IFTHENELSE" *)
    (*    | "$NonRecursiveFcnSpec"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$Pair"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$RcdConstructor"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$RcdSelect"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$RecursiveFcnSpec"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$Seq"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$SquareAct"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$SetEnumerate"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$SF"  as x -> failwith ("Unknown operator " ^ x ^"!")
    | "$SetOfAll" as x  -> failwith ("Unknown operator " ^ x ^"!")
    | "$SetOfRcds" as x  -> failwith ("Unknown operator " ^ x ^"!")
    | "$SetOfFcns" as x  -> failwith ("Unknown operator " ^ x ^"!")
    | "$SubsetOf" as x  -> failwith ("Unknown operator " ^ x ^"!")
    | "$Tuple" as x  -> failwith ("Unknown operator " ^ x ^"!") *)
    (* | "$TemporalExists" -> "\\EE" *)
    (* | "$TemporalForall" -> "\\AA" *)
    (* | "$UnboundedChoose" -> "CHOOSE" *)
    | "$UnboundedExists" -> `Exists
    | "$UnboundedForall" -> `Forall
    (*    | "$WF" as x  -> failwith ("Unknown operator " ^ x ^"!")
    | "$Nop" as x -> failwith ("Unknown operator " ^ x ^"!") *)
    (*    | "$Qed" -> "QED" *)
    (*    | "$Pfcase" -> "CASE" *)
    (*    | "$Have" -> "HAVE" *)
    (*    | "$Take" -> "TAKE" *)
    (*    | "$Pick" -> "PICK" *)
    (*    | "$Witness" -> "WITNESS" *)
    (*    | "$Suffices" -> "SUFFICES" *)
    (* manual additions *)
    | "\\land" -> `And
    | "\\lor" -> `Or
    | "TRUE" -> `True
    | "FALSE" -> `False
    | "=" -> `Eq
    | "=>" -> `Imply
    | "/=" -> `Neq
    | "\\lnot" -> `Not
    | "$FcnApply" -> `Apply
    | x -> `Undefined x (* catchall case *)
end

let expr_formatter = new formatter

let mk_fmt (f : fc -> 'a -> fc) term_db (goal : 'a) =
  let initial_commands = [comm "End of initial commands";decl [] "apply" (var "u -> u -> u");decl [] "u" (var "type")(* ;include_ "\"prelude.nun\"" *);comm "Initial commands";] in
  let acc = (initial_commands, term_db, Unknown "starting term", true) in
  let (l,_,_,_) = (f acc goal) in
  l
      
let fmt_expr = mk_fmt (expr_formatter#expr)

let fmt_assume_prove = mk_fmt (expr_formatter#assume_prove)

			    

			    
			    
