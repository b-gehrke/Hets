(* 
Description :  Functions faciliating exporting theorems from HOL Light to HETS. Theorem database generation adapted from Examples/update_database.ml
               in the hol light source code distribution.

Copyright   :  (c) Jonathan von Schroeder, DFKI GmbH 2010
License     :  GPLv2 or higher, see LICENSE.txt - for original license see 
               LICENSE txt in this directory or the HOL Light
               source distribution

Maintainer  :  jonathan.von_schroeder@dfki.de
Stability   :  experimental

 *)

(* !!!!!!! You must set this to point at the source directory in
   !!!!!!! which OCaml was built. (And don't do "make clean" beforehand.)
 
  the provided value is an example that works with a standard ocaml installation (aptitude install ocaml) on ubuntu

 *)

let ocaml_source_dir = "/usr/lib/ocaml/compiler-libs/";;

let sentences = ref ([]:(string*term)list);;

do_list (fun s -> Topdirs.dir_directory(Filename.concat ocaml_source_dir s))
        ["parsing"; "typing"; "toplevel"; "utils"];;

(* This must be loaded first! It is stateful, and affects Predef *)
#load "ident.cmo";;

#load "misc.cmo";;
#load "path.cmo";;
#load "types.cmo";;
#load "btype.cmo";;
#load "tbl.cmo";;
#load "subst.cmo";;
#load "predef.cmo";;
#load "datarepr.cmo";;
#load "config.cmo";;
#load "consistbl.cmo";;
#load "clflags.cmo";;
#load "env.cmo";;
#load "ctype.cmo";;
#load "printast.cmo";;
#load "oprint.cmo";;
#load "primitive.cmo";;
#load "printtyp.cmo";;

(* ------------------------------------------------------------------------- *)
(* Get the toplevel environment as raw data.                                 *)
(* ------------------------------------------------------------------------- *)

let get_value_bindings env =
   let rec get_val acc = function
        | Env.Env_empty -> acc
        | Env.Env_value (next, ident, val_descr) ->
                get_val ((ident,val_descr)::acc) next
        | Env.Env_type (next,_,_) -> get_val acc next
        | Env.Env_exception (next,_,_) -> get_val acc next
        | Env.Env_module (next,_,_) -> get_val acc next
        | Env.Env_modtype (next,_,_) -> get_val acc next
        | Env.Env_class (next,_,_) -> get_val acc next
        | Env.Env_cltype (next,_,_) -> get_val acc next
        | Env.Env_open (next,_) -> get_val acc next
  in get_val [] (Env.summary env);;

(* ------------------------------------------------------------------------- *)
(* Convert a type to a string, for ease of comparison.                       *)
(* ------------------------------------------------------------------------- *)

let type_to_str (x : Types.type_expr) =
  Printtyp.type_expr Format.str_formatter x;
         Format.flush_str_formatter ();;

(* ------------------------------------------------------------------------- *)
(* Remove bindings in first list from second assoc list (all ordered).       *)
(* ------------------------------------------------------------------------- *)

let rec demerge s l =
  match (s,l) with
    u::t,(x,y as p)::m ->
        if u = x then demerge t m
        else if u < x then demerge t l
        else p::(demerge s m)
  | _ -> l;;

(* ------------------------------------------------------------------------- *)
(* Incrementally update database.                                            *)
(* ------------------------------------------------------------------------- *)

let update_database =
  let uinfo = ((ref 0, ref undefined), (ref 0, ref undefined)) in
  let listify l = if l = [] then "[]"
                  else "[\n"^end_itlist (fun a b -> a^";\n"^b) l^"\n]\n" in
  let purenames = map (fun n -> "\""^n^"\"")
  and pairnames = map (fun n -> "\""^n^"\","^n) in
  let update_database' tstr vname value_bindings_checked theorem_bindings_existing = 
    let old_count = !value_bindings_checked
    and old_ths = !theorem_bindings_existing in
    let all_bnds = get_value_bindings (!Toploop.toplevel_env) in
    let new_bnds = funpow old_count tl all_bnds in
    let new_count = old_count + length new_bnds
    and new_ths =
      rev_itlist (fun (ident,val_descr) ->
        let n = Ident.name ident in
        if type_to_str val_descr.Types.val_type = tstr & n <> "it"
        then (n |-> ()) else undefine n) new_bnds old_ths in
    value_bindings_checked := new_count;
    if new_ths = old_ths then () else
    (print_string "Updating search database\n";
     theorem_bindings_existing := new_ths;
     let all_ths = combine (fun _ _ -> ()) (fun _ -> false) old_ths new_ths in
     let del_ths = combine (fun _ _ -> ()) (fun _ -> true) all_ths new_ths
     and add_ths = combine (fun _ _ -> ()) (fun _ -> true) all_ths old_ths in
     let del_names = mergesort (<) (foldr (fun a _ l -> a::l) del_ths [])
     and add_names = mergesort (<) (foldr (fun a _ l -> a::l) add_ths []) in
     let exptext =
      vname ^ " :=\n merge (increasing fst) (demerge "^
      (listify(purenames del_names))^
      " (!"^vname^")) "^
      (listify(pairnames add_names))^
      ";;\n" in
     (let filename = Filename.temp_file "database" ".ml" in
      file_of_string filename exptext;
      loadt filename;
      Sys.remove filename)) in
   fun () ->
      update_database' "thm" "theorems" (fst (fst uinfo)) (snd (fst uinfo));
      update_database' "term" "sentences" (fst (snd uinfo)) (snd (snd uinfo));;

let search' selector ts t = let filter_exp = can (term_match [] t) in
                            let sel = filter_exp o selector o snd in
                            let matching = filter sel ts in
                            try Some (List.hd matching) with
                            Failure _ -> None;;

let search_theorem t = search' concl (!theorems) t;;

let search_term t = let id x =x in search' id (!sentences) t;;

type sentence = { id : int ; axiom : bool ; incoming : int list ; tname : string };;

let dummy_sentence = { id=0 ; axiom = true; incoming = []; tname = ""};;

let (export,export_all) = let is_axiom th = let p = can (term_match [] (concl th)) in
                                     exists p (hyp th)
                   and fresh_id = let id = ref 0 in
                                  fun () ->
                                  id := (!id)+1;
                                  (!id) in
                  let insert sens th thn = let i = fresh_id() in 
                                      Hashtbl.add sens (concl th)
                                    { id = i; axiom = is_axiom th; tname = thn; 
                                      incoming = map (fun x -> let s = Hashtbl.find sens x in s.id) (filter ((<>)(concl th)) (hyp th)); } in
                  let hashtbl_to_list htbl = Hashtbl.fold (fun k v l -> (k,v)::l) htbl [] in
                  let rec expand sens th tname = 
                    let rec expand_sen sens tm = match search_theorem tm with
                                              Some (tname,th) -> expand sens th tname
                                            | None -> match search_term tm with
                                                        Some (tname,t) -> Hashtbl.remove sens tm;
                                                                          Hashtbl.add sens t
                                                        { id = fresh_id(); axiom = true;
                                                          incoming = []; tname = tname }
                                                      | None -> Hashtbl.replace sens tm 
                                                        { id = fresh_id(); axiom = true;
                                                         incoming = []; tname = "" }
                    and hashtbl_contains = Hashtbl.mem sens in
                    let tms = filter (not o hashtbl_contains) (hyp th) in
                    map (fun x -> Hashtbl.add sens x dummy_sentence) tms;
                    insert sens th tname;
                    map (expand_sen sens) tms;
                    () in
                  let e = fun tname ->
                       let t = (snd o List.hd) (filter (((=)tname) o fst) (!theorems))
                       and sens = Hashtbl.create ((List.length (!theorems))/10) in
                        expand sens t tname;
                        hashtbl_to_list sens
                   and e_a = fun () ->
                       let sens = Hashtbl.create (List.length (!theorems)) in
                        map (fun x -> if (((Hashtbl.mem sens) o concl o snd) x) then ()
                         else expand sens (snd x) (fst x)
                         ) (!theorems);
                        hashtbl_to_list sens in
                   (e,e_a);;

let pp_term_sen_list fmt =
                      let rec pp_list pp_el fmt = function
		        | [h] -> Format.fprintf fmt "%a" pp_el h
			| h::t ->
			   Format.fprintf fmt "%a%s@,%a"
			   pp_el h ", " (pp_list pp_el) t
			| [] -> ()
                      and pp_bool fmt x = Format.fprintf fmt "%s" (if x then "True" else "False") in
	              let rec pp_hol_type fmt = function
                        | Tyvar s -> Format.fprintf fmt "TyVar %S" s
			| Tyapp (s,ts) -> Format.fprintf fmt "TyApp %S [%a]" s (pp_list pp_hol_type) ts in
                      let rec pp_term fmt = function
                        | Var (s,h) -> Format.fprintf fmt "Var %S (%a)" s pp_hol_type h
		        | Const (s,h) -> Format.fprintf fmt "Const %S (%a)" s pp_hol_type h
		        | Comb (t1,t2) -> Format.fprintf fmt "Comb (%a) (%a)" pp_term t1 pp_term t2
		        | Abs (t1,t2) -> Format.fprintf fmt "Abs (%a) (%a)" pp_term t1 pp_term t2 in
                      let pp_sen fmt s = Format.fprintf fmt "SenInfo %u %a [%a] %S" s.id pp_bool s.axiom (pp_list (fun f -> Format.fprintf f "%u")) s.incoming s.tname in
                      let pp_term_sen_tuple fmt (t,s) = Format.fprintf fmt "(%a, %a)" pp_term t pp_sen s in
                    Format.fprintf fmt "[%a]" (pp_list pp_term_sen_tuple);;

theorems := [];;
sentences := [];;

update_database();;
