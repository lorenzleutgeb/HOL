(* generated by Lem from compile.lem *)
open bossLib Theory Parse res_quanTheory
open finite_mapTheory listTheory pairTheory pred_setTheory integerTheory
open fsetTheory
open set_relationTheory sortingTheory stringTheory wordsTheory

val _ = new_theory "Compile"

open BytecodeTheory MiniMLTheory

(*open MiniML*)

(* Intermediate language for MiniML compiler *)

(* Syntax *)

(* applicative primitives with bytecode counterparts *)
val _ = Hol_datatype `
 Cprim2 = CAdd | CSub | CMult | CDiv | CMod | CLt | CEq`;

(* other primitives *)
val _ = Hol_datatype `
 Clprim = CLeq | CIf | CAnd | COr`;


val _ = Hol_datatype `
 Cpat =
    CPvar of num
  | CPlit of lit
  | CPcon of num => Cpat list`;


val _ = Hol_datatype `
 Cexp =
    CRaise of error
  | CVar of num
  | CLit of lit
  | CCon of num => Cexp list
  | CTagEq of Cexp => num
  | CProj of Cexp => num
  | CMat of num => (Cpat # Cexp) list
  | CLet of num list => Cexp list => Cexp
  | CLetfun of bool => num list => (num list # Cexp) list => Cexp
  | CFun of num list => Cexp
  | CCall of Cexp => Cexp list
  | CPrim2 of Cprim2 => Cexp => Cexp
  | CLprim of Clprim => Cexp list`;


(* TODO: move to lem? *)
(*val range : forall 'a 'b. ('a,'b) Pmap.map -> 'b set*)
(*val least : (num -> bool) -> num*)
(*val replace : forall 'a. 'a -> num -> 'a list -> 'a list*)
(*val num_set_foldl : forall 'a. ('a -> num -> 'a) -> 'a -> num set -> 'a*)
(*val int_to_num : int -> num*)
(*val image : forall 'a 'b. ('a -> 'b) -> 'a set -> 'b set*)

 val remove_mat_exp_defn = Hol_defn "remove_mat_exp" `

(remove_mat_exp (Mat (Var v) pes) =
  let pes = FOLDR  (\ (p,e) pes . (p, remove_mat_exp e)::pes)  []  pes in
  Mat (Var v) pes)
/\
(remove_mat_exp (Mat e pes) =
  let pes = FOLDR  (\ (p,e) pes . (p, remove_mat_exp e)::pes)  []  pes in
  Let "" e (Mat (Var "") pes))
/\
(remove_mat_exp (Raise err) = Raise err)
/\
(remove_mat_exp (Val u) = Val u)
/\
(remove_mat_exp (Con cn es) = Con cn (MAP remove_mat_exp es))
/\
(remove_mat_exp (Var v) = Var v)
/\
(remove_mat_exp (Fun v e) = Fun v (remove_mat_exp e))
/\
(remove_mat_exp (App op e1 e2) = App op (remove_mat_exp e1) (remove_mat_exp e2))
/\
(remove_mat_exp (Log lg e1 e2) = Log lg (remove_mat_exp e1) (remove_mat_exp e2))
/\
(remove_mat_exp (If e1 e2 e3) = If (remove_mat_exp e1) (remove_mat_exp e2) (remove_mat_exp e3))
/\
(remove_mat_exp (Let v e1 e2) = Let v (remove_mat_exp e1) (remove_mat_exp e2))
/\
(remove_mat_exp (Letrec defs e) =
  Letrec
    (MAP (\ (v1,v2,e) . (v1,v2,remove_mat_exp e)) defs)
    (remove_mat_exp e))`;

val _ = Defn.save_defn remove_mat_exp_defn;

 val remove_Gt_Geq_defn = Hol_defn "remove_Gt_Geq" `

(remove_Gt_Geq (Raise err) = Raise err)
/\
(remove_Gt_Geq (Val v) = Val v)
/\
(remove_Gt_Geq (Con cn es) = Con cn (MAP remove_Gt_Geq es))
/\
(remove_Gt_Geq (Var vn) = Var vn)
/\
(remove_Gt_Geq (Fun vn e) = Fun vn (remove_Gt_Geq e))
/\
(remove_Gt_Geq (App (Opb Gt) e1 e2) = App (Opb Lt) (remove_Gt_Geq e2) (remove_Gt_Geq e1))
/\
(remove_Gt_Geq (App (Opb Geq) e1 e2) = App (Opb Leq) (remove_Gt_Geq e2) (remove_Gt_Geq e1))
/\
(remove_Gt_Geq (App op e1 e2) = App op (remove_Gt_Geq e1) (remove_Gt_Geq e2))
/\
(remove_Gt_Geq (Log lg e1 e2) = Log lg (remove_Gt_Geq e1) (remove_Gt_Geq e2))
/\
(remove_Gt_Geq (If e1 e2 e3) = If (remove_Gt_Geq e1) (remove_Gt_Geq e2) (remove_Gt_Geq e3))
/\
(remove_Gt_Geq (Mat e pes) = Mat (remove_Gt_Geq e) (MAP (\ (p,e) . (p,remove_Gt_Geq e)) pes))
/\
(remove_Gt_Geq (Let vn e b) = Let vn (remove_Gt_Geq e) (remove_Gt_Geq b))
/\
(remove_Gt_Geq (Letrec defs e) = Letrec (MAP (\ (fn,vn,e) .
  (fn,vn,remove_Gt_Geq e)) defs) (remove_Gt_Geq e))`;

val _ = Defn.save_defn remove_Gt_Geq_defn;

val _ = Define `
 (least_not_in s = (LEAST) (\ n . ~ (n IN s)))`;


val _ = Hol_datatype `
 exp_to_Cexp_state =
  <| m : (string,num) fmap
   ; w : (num,string) fmap
   ; n : num
   |>`;


val _ = Define `
 (extend s vn =
  let m' = FUPDATE  s.m ( vn, s.n) in
  let w' = FUPDATE  s.w ( s.n, vn) in
   s with<| m := m'; w := w'; n := s.n+1 |>)`;


 val pat_to_Cpat_defn = Hol_defn "pat_to_Cpat" `

(pat_to_Cpat cm (s, Pvar vn) =
  let s' = extend s vn in (s', CPvar s.n))
/\
(pat_to_Cpat cm (s, Plit l) = (s, CPlit l))
/\
(pat_to_Cpat cm (s, Pcon cn ps) =
  let (s',ps) = FOLDR 
    (\ p (s,ps) . let (s',p) = pat_to_Cpat cm (s,p) in (s',p::ps))  (s,[]) 
         ps in
  (s', CPcon (FAPPLY  cm  cn) ps))`;

val _ = Defn.save_defn pat_to_Cpat_defn;

(* TODO: make exp_to_Cexp avoid skipping variable numbers (i.e. only add
 * variables that will make it to a top-level declaration to the returned state) *)

 val exp_to_Cexp_defn = Hol_defn "exp_to_Cexp" `

(exp_to_Cexp d cm (s, Raise err) = (s, CRaise err))
/\
(exp_to_Cexp d cm (s, Val (Lit l)) = (s, CLit l))
/\
(exp_to_Cexp d cm (s, Con cn es) =
  (s, CCon (FAPPLY  cm  cn) (MAP (\ e . let (_s,e) = exp_to_Cexp NONE cm (s,e) in e) es)))
/\
(exp_to_Cexp d cm (s, Var vn) =
  (s, CVar ((case d of SOME _ => 0 | NONE => FAPPLY  s.m  vn ))))
/\
(exp_to_Cexp d cm (s, Fun vn e) =
  let s' = extend s vn in
  let (s',Ce) = exp_to_Cexp NONE cm (s', e) in
  (s, CFun [s.n] Ce))
/\
(exp_to_Cexp d cm (s, App (Opn opn) e1 e2) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (_s,Ce2) = exp_to_Cexp NONE cm (s, e2) in
  (s, CPrim2 ((case opn of
                Plus   => CAdd
              | Minus  => CSub
              | Times  => CMult
              | Divide => CDiv
              | Modulo => CMod
              ))
      Ce1 Ce2))
/\
(exp_to_Cexp d cm (s, App (Opb opb) e1 e2) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (_s,Ce2) = exp_to_Cexp NONE cm (s, e2) in
  (s, (case opb of
        Lt => CPrim2 CLt Ce1 Ce2
      | Leq => CLprim CLeq [Ce1;Ce2]
      )))
/\
(exp_to_Cexp d cm (s, App Equality e1 e2) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (_s,Ce2) = exp_to_Cexp NONE cm (s, e2) in
  (s, CPrim2 CEq Ce1 Ce2))
/\
(exp_to_Cexp d cm (s, App Opapp e1 e2) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (_s,Ce2) = exp_to_Cexp NONE cm (s, e2) in
  (s, CCall Ce1 [Ce2]))
/\
(exp_to_Cexp d cm (s, Log log e1 e2) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (_s,Ce2) = exp_to_Cexp NONE cm (s, e2) in
  (s, CLprim ((case log of
                And => CAnd
              | Or  => COr
              ))
      [Ce1;Ce2]))
/\
(exp_to_Cexp d cm (s, If e1 e2 e3) =
  let (_s,Ce1) = exp_to_Cexp NONE cm (s, e1) in
  let (s',Ce2) = exp_to_Cexp d cm (s, e2) in
  let (s',Ce3) = exp_to_Cexp d cm (s', e3) in
  ((case d of NONE => s | SOME _ => s' ), CLprim CIf [Ce1;Ce2;Ce3]))
/\
(exp_to_Cexp d cm (s, Mat (Var vn) pes) =
  let (s',Cpes) = FOLDR 
    (\ (p,e) (s,Cpes) .
      let (s,Cp) = pat_to_Cpat cm (s,p) in
      let (s,Ce) = exp_to_Cexp d cm (s,e) in
      (s,(Cp,Ce)::Cpes))   (s,[]) 
          pes in
  ((case d of NONE => s | SOME _ => s' ), CMat (FAPPLY  s.m  vn) Cpes))
/\
(exp_to_Cexp d cm (s, Let vn e b) =
  let s' = extend s vn in
  let (_s,Ce) = exp_to_Cexp NONE cm (s, e) in
  let (s',Cb) = exp_to_Cexp d cm (s', b) in
  ((case d of NONE => s | SOME _ => s' ), CLet [s.n] [Ce] Cb))
/\
(exp_to_Cexp d cm (s, Letrec defs b) =
  let (s',fns) = FOLDR 
    (\ (d,_vn,_e) (s,fns) . (extend s d, s.n::fns))       (s,[]) 
          defs in
  let Cdefs = FOLDR 
    (\ (_d,vn,e) Cdefs .
      let (_s,Ce) = exp_to_Cexp NONE cm (extend s' vn, e) in
      ([s'.n],Ce)::Cdefs)      [] 
          defs in
  let (s',Cb) = exp_to_Cexp d cm (s',b) in
  ((case d of NONE => s | SOME _ => s' ), CLetfun T fns Cdefs Cb))`;

val _ = Defn.save_defn exp_to_Cexp_defn;

(* TODO: semantics *)
(* TODO: simple type system and checker *)

 val free_vars_defn = Hol_defn "free_vars" `

(free_vars (CRaise _) = {})
/\
(free_vars (CVar n) = {n})
/\
(free_vars (CLit _) = {})
/\
(free_vars (CCon _ es) =
  FOLDL (\ s e . s UNION free_vars e) {} es)
/\
(free_vars (CTagEq e _) = free_vars e)
/\
(free_vars (CProj e _) = free_vars e)
/\
(free_vars (CMat v pes) =
  FOLDL (\ s (p,e) . s UNION free_vars e) {v} pes)
/\
(free_vars (CLet xs es e) =
  FOLDL (\ s e . s UNION free_vars e)
  (free_vars e DIFF LIST_TO_SET xs) es)
/\
(free_vars (CLetfun T ns defs e) =
  FOLDL (\ s (vs,e) .
    s UNION (free_vars e DIFF (LIST_TO_SET ns UNION
                            LIST_TO_SET vs)))
  (free_vars e DIFF LIST_TO_SET ns) defs)
/\
(free_vars (CLetfun F ns defs e) =
  FOLDL (\ s (vs,e) .
    s UNION (free_vars e DIFF LIST_TO_SET vs))
  (free_vars e DIFF LIST_TO_SET ns) defs)
/\
(free_vars (CFun xs e) = free_vars e DIFF (LIST_TO_SET xs))
/\
(free_vars (CCall e es) =
  FOLDL (\ s e . s UNION free_vars e)
  (free_vars e) es)
/\
(free_vars (CPrim2 _ e1 e2) = free_vars e1 UNION free_vars e2)
/\
(free_vars (CLprim _ es) =
  FOLDL (\ s e . s UNION free_vars e) {} es)`;

val _ = Defn.save_defn free_vars_defn;

(* Remove pattern-matching using continuations *)
(* TODO: more efficient method *)
(*val remove_mat : Cexp -> Cexp*)

 val remove_mat_vp_defn = Hol_defn "remove_mat_vp" `

(remove_mat_vp fk sk v (CPvar pv) =
  CLet [pv] [CVar v] sk)
/\
(remove_mat_vp fk sk v (CPlit l) =
  CLprim CIf [CPrim2 CEq (CVar v) (CLit l);
    sk; (CCall (CVar fk) [])])
/\
(remove_mat_vp fk sk v (CPcon cn ps) =
  CLprim CIf [CTagEq (CVar v) cn;
    remove_mat_con fk sk v 0 ps;
    CCall (CVar fk) []])
/\
(remove_mat_con fk sk v n [] = sk)
/\
(remove_mat_con fk sk v n (p::ps) =
  let v' = least_not_in ((INSERT) v (free_vars sk)) in
  CLet [v'] [CProj (CVar v) n]
    (remove_mat_vp fk (remove_mat_con fk sk v (n+1) ps) v' p))`;

val _ = Defn.save_defn remove_mat_vp_defn;

 val remove_mat_defn = Hol_defn "remove_mat" `

(remove_mat (CMat v pes) = remove_mat_var v pes)
/\
(remove_mat (CRaise err) = CRaise err)
/\
(remove_mat (CVar n) = CVar n)
/\
(remove_mat (CLit l) = CLit l)
/\
(remove_mat (CCon n es) = CCon n (MAP remove_mat es))
/\
(remove_mat (CTagEq e n) = CTagEq (remove_mat e) n)
/\
(remove_mat (CProj e n) = CProj (remove_mat e) n)
/\
(remove_mat (CLet xs es e) = CLet xs (MAP remove_mat es) (remove_mat e))
/\
(remove_mat (CLetfun b ns defs e) = CLetfun b ns (MAP (\ (vs,e) . (vs,remove_mat e)) defs) (remove_mat e))
/\
(remove_mat (CFun ns e) = CFun ns (remove_mat e))
/\
(remove_mat (CCall e es) = CCall (remove_mat e) (MAP remove_mat es))
/\
(remove_mat (CPrim2 o2 e1 e2) = CPrim2 o2 (remove_mat e1) (remove_mat e2))
/\
(remove_mat (CLprim ol es) = CLprim ol (MAP remove_mat es))
/\
(remove_mat_var v [] = CRaise Bind_error)
/\
(remove_mat_var v ((p,e)::pes) =
  let sk = remove_mat e in
  let fk = least_not_in ((INSERT) v (free_vars sk)) in
  CLetfun F [fk] [([],(remove_mat_var v pes))]
    (remove_mat_vp fk sk v p))`;

val _ = Defn.save_defn remove_mat_defn;

(* TODO: make clobbered declarations be replaced on the stack *)
(* TODO: collapse nested functions *)
(* TODO: collapse nested lets *)
(* TODO: Letfun introduction and reordering *)
(* TODO: let floating *)
(* TODO: removal of redundant expressions *)
(* TODO: simplification (e.g., constant folding) *)
(* TODO: registers, register allocation, greedy shuffling? *)
(* TODO: bytecode optimizer: repeated Pops, unreachable code (e.g. after a Jump) *)

(* values in compile-time environment *)
val _ = Hol_datatype `
 ctbind = CTLet of num | CTArg of num | CTEnv of num | CTRef of num`;

(* CTLet n means stack[sz - n]
   CTArg n means stack[sz + n]
   CTEnv n means El n of the environment, which is at stack[sz]
   CTRef n means El n of the environment, but it's a ref pointer *)

(*open Bytecode*)

val _ = Hol_datatype `
 compiler_state =
  <| env: (num,ctbind) fmap
   ; sz: num
   ; code: bc_inst list (* reversed *)
   ; tail: (num # num)option
   ; next_label: num
   (* not modified on return: *)
   ; decl: ((num,ctbind) fmap # num # num set)option
   ; inst_length: bc_inst -> num
   |>`;


val _ = Define `
 i0 = & 0`;

val _ = Define `
 i1 = & 1`;

val _ = Define `
 i2 = & 2`;


 val error_to_int_defn = Hol_defn "error_to_int" `

(error_to_int Bind_error = i0)
/\
(error_to_int Div_error = i1)`;

val _ = Defn.save_defn error_to_int_defn;

 val prim2_to_bc_defn = Hol_defn "prim2_to_bc" `

(prim2_to_bc CAdd = Add)
/\
(prim2_to_bc CSub = Sub)
/\
(prim2_to_bc CMult = Mult)
/\
(prim2_to_bc CDiv = Div2) (* TODO *)
/\
(prim2_to_bc CMod = Mod2) (* TODO *)
/\
(prim2_to_bc CLt = Less)
/\
(prim2_to_bc CEq = Equal)`;

val _ = Defn.save_defn prim2_to_bc_defn;

val _ = Define `
 emit = FOLDL
  (\ s i .  s with<| next_label := s.next_label + s.inst_length i + 1;
                        code := i :: s.code |>)`;


 val compile_varref_defn = Hol_defn "compile_varref" `

(compile_varref s (CTLet n) = emit s [Stack (Load (s.sz - n))])
/\
(compile_varref s (CTArg n) = emit s [Stack (Load (s.sz + n))])
/\
(compile_varref s (CTEnv n) = emit s [Stack (Load s.sz); Stack (El n)])
/\
(compile_varref s (CTRef n) = emit (compile_varref s (CTEnv n)) [Deref])`;

val _ = Defn.save_defn compile_varref_defn;

val _ = Define `
 (incsz s =  s with<| sz := s.sz + 1 |>)`;

val _ = Define `
 (decsz s =  s with<| sz := s.sz - 1 |>)`;

val _ = Define `
 (sdt s = ( s with<| decl := NONE ; tail := NONE |>, (s.decl, s.tail)))`;

val _ = Define `
 (ldt (d,t) s =  s with<| decl := d ; tail := t |>)`;


(* TODO: elsewhere? *)
 val find_index_defn = Hol_defn "find_index" `

(find_index y [] _ = NONE)
/\
(find_index y (x::xs) (n:num) = if x = y then SOME n else find_index y xs (n+1))`;

val _ = Defn.save_defn find_index_defn;

(* helper for reconstructing closure environments *)
val _ = Hol_datatype `
 cebind = CEEnv of num | CERef of num`;


 val emit_ec_defn = Hol_defn "emit_ec" `

(emit_ec (CEEnv fv) s = incsz (compile_varref s (FAPPLY  s.env  fv)))
/\
(emit_ec (CERef j) s = incsz (emit s [Stack (Load (s.sz - j))]))`;

val _ = Defn.save_defn emit_ec_defn;

 val replace_calls_defn = Hol_defn "replace_calls" `

(replace_calls j [_] c = c)
/\
(replace_calls j ((_,lab)::(jl,l)::ls) c =
  replace_calls j ((jl,l)::ls)
    (REPLACE_ELEMENT (Call lab) (j - jl) c))`;

val _ = Defn.save_defn replace_calls_defn;

 val fold_num_defn = Hol_defn "fold_num" `

(fold_num f a (n:num) = if n = 0 then a else fold_num f (f a) (n - 1))`;

val _ = Defn.save_defn fold_num_defn;

 val compile_defn = Hol_defn "compile" `

(compile s (CRaise err) =
  incsz (emit s [Stack (PushInt (error_to_int err)); Exception]))
/\
(compile s (CLit (IntLit i)) =
  incsz (emit s [Stack (PushInt i)]))
/\
(compile s (CLit (Bool b)) =
  incsz (emit s [Stack (PushInt (bool_to_int b))]))
/\
(compile s (CVar n) =
  (case s.decl of
    NONE =>
      incsz (compile_varref s (FAPPLY  s.env  n))
  | SOME (env0,sz0,vs) => (* TODO: avoid excessive copying? same for tail calls *)
      let k = s.sz - sz0 in
      let n = CARD vs in
      let s = if k < n then
        fold_num (\ s . incsz (emit s [Stack (PushInt i0)])) s (n - k)
        else s in
      let (s,j,env) = num_set_foldl
        (\ (s,j,env) v . (incsz (compile_varref s (FAPPLY  s.env  v)),
                             j+1,
                             FUPDATE  env ( v, (CTLet j))))
             (s,sz0+1,env0) vs in
      (* vn, ..., v1, x1, x2, ..., xk, *)
      (*   with k >= n (and the first few xs are 0s) *)
      let j = k - n in
      let s = fold_num (\ s . emit s [Stack (Store ((n - 1)+j))])
                            s n in
      (* x1, ..., xj, vn, ..., v1, *)
      let s = if j = 0 then s else
        emit s [Stack (PushInt i0); Stack (Pops j); Stack Pop] in
      (* vn, ..., v1, *)
       s with<| sz := sz0 + n; env := env |>
  ))
/\
(compile s (CCon n []) =
  incsz (emit s [Stack (PushInt (& n))]))
/\
(compile s (CCon n es) =
  let z = s.sz + 1 in
  let (s,dt) = sdt s in
  let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
  let s = emit (ldt dt s) [Stack (Cons n (LENGTH es))] in
   s with<| sz := z |>)
/\
(compile s (CTagEq e n) =
  let (s,dt) = sdt s in
  ldt dt (emit (compile s e) [Stack (TagEquals n)]))
/\
(compile s (CProj e n) =
  let (s,dt) = sdt s in
  ldt dt (emit (compile s e) [Stack (El n)]))
/\
(compile s (CMat _ _) =
  incsz (emit s [Stack (PushInt i2); Exception]))
/\
(compile s (CLet xs es e) =
  let z = s.sz + 1 in
  let (s,dt) = sdt s in
  let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
  compile_bindings s.env z e 0 (ldt dt s) xs)
/\
(compile s (CLetfun recp ns defs e) =
  let z = s.sz + 1 in
  let s = compile_closures (if recp then SOME ns else NONE) s defs in
  compile_bindings s.env z e 0 s ns)
/\
(compile s (CFun xs e) =
  compile_closures NONE s [(xs,e)])
/\
(compile s (CCall e es) =
  let n = LENGTH es in
  let t = s.tail in
  let (s,dt) = sdt s in
  let s = (case t of
    NONE =>
    let s = compile s e in
    let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
    (* argn, ..., arg2, arg1, Block 0 [CodePtr c; env], *)
    let s = emit s [Stack (Load n); Stack (El 1)] in
    (* env, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    let s = emit s [Stack (Load (n+1)); Stack (El 0)] in
    (* CodePtr c, env, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    emit s [CallPtr]
    (* before: env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    (* after:  retval, *)
  | SOME (j,k) =>
    let n0 = k+1+1+j+1 in
    let n1 = 1+1+1+n+1 in
    let (j,s) = if n0 < n1 then
      let j = n1 - n0 in
        (j,fold_num (\ s . incsz (emit s [Stack (PushInt i0)])) s j)
      else (0,s) in
    let s = compile s e in
    let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
    (* argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01,
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+1+j+k+1))] in
    (* CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01,
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+1)); Stack (El 1)] in
    (* env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01,
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+2)); Stack (El 0)] in
    (* CodePtr c, env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ... 01,
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let j = n0 + j - n1 in
    let s = fold_num (\ s . emit s [Stack (Store ((n1 - 1)+j))]) s n1 in
    let s = if j = 0 then s else
      emit s [Stack (PushInt i0); Stack (Pops j); Stack Pop] in
    emit s [JumpPtr]
  ) in
  ldt dt  s with<| sz := s.sz - n |>)
/\
(compile s (CPrim2 op e1 e2) =
  let (s,dt) = sdt s in
  let s = compile s e1 in
  let s = compile s e2 in
  decsz (ldt dt (emit s [Stack (prim2_to_bc op)])))
/\
(compile s (CLprim CLeq [e1;e2]) =
  let s = incsz (emit s [Stack (PushInt i1)]) in
  let s = incsz (emit s [Stack (PushInt i0)]) in
  let (s,dt) = sdt s in
  let s = compile s e1 in
  let s = compile s e2 in
  let s = emit s [Stack Sub; Stack Less; Stack Sub] in
  ldt dt  s with<| sz := s.sz - 3 |>)
/\
(compile s (CLprim CIf [e1;e2;e3]) =
  let (s,dt) = sdt s in
  let s = ldt dt (compile s e1) in
  let s = emit s [JumpNil 0; Jump 0] in
  let j1 = LENGTH s.code in
  let n1 = s.next_label in
  let s = compile (decsz s) e2 in
  let s = emit s [Jump 0] in
  let j2 = LENGTH s.code in
  let n2 = s.next_label in
  let s = compile (decsz s) e3 in
  let n3 = s.next_label in
  let j3 = LENGTH s.code in
   s with<| code :=
      (REPLACE_ELEMENT (Jump n3) (j3 - j2)
      (REPLACE_ELEMENT (Jump n2) (j3 - j1)
      (REPLACE_ELEMENT (JumpNil n1) (j3 - j1 + 1) s.code))) |>)
/\
(compile s (CLprim CAnd [e1;e2]) =
  let (s,dt) = sdt s in
  let s = compile s e1 in
  let s = emit s [JumpNil 0] in
  let j = LENGTH s.code in
  let s = ldt dt (compile (decsz s) e2) in
   s with<| code :=
      REPLACE_ELEMENT (JumpNil s.next_label)
      (LENGTH s.code - j) s.code |>)
/\
(compile s (CLprim COr [e1;e2]) =
  let (s,dt) = sdt s in
  let s = compile s e1 in
  let s = emit s [JumpNil 0; Stack (PushInt i1); Jump 0] in
  let j = LENGTH s.code in
  let n1 = s.next_label in
  let s = ldt dt (compile (decsz s) e2) in
  let n2 = s.next_label in
  let j3 = LENGTH s.code in
   s with<| code :=
      (REPLACE_ELEMENT (Jump n2) (j3 - j)
      (REPLACE_ELEMENT (JumpNil n1) (j3 - j - 2) s.code)) |>)
/\
(compile_bindings env0 sz1 e n s [] =
  (case s.tail of
    NONE =>
    let s = compile s e in
    (case s.decl of
      SOME _ => s
    | NONE =>
        let s = emit s [Stack (Pops n)] in
         s with<| env := env0 ; sz := sz1 |>
    )
  | SOME (j,k) =>
    let s =  s with<| tail := SOME (j,k+n) |> in
    let s = compile s e in
     s with<| env := env0 ; sz := sz1 |>
  ))
/\
(compile_bindings env0 sz1 e n s (x::xs) =
  compile_bindings env0 sz1 e
    (n+1) (* parentheses below because Lem sucks *)
    ( s with<| env := FUPDATE  s.env ( x, (CTLet (sz1 + n))) |>)
    xs)
/\
(compile_closures nso s defs =
  (* calling convention:
   * before: env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env],
   * thus, since env = stack[sz], argk should be CTArg (2 + n - k)
   * after:  retval,
       PushInt 0, Ref
       ...            (* create RefPtrs for recursive closures *)
       PushInt 0, Ref                       RefPtr 0, ..., RefPtr 0, rest
       PushInt 0                            0, RefPtr 0, ..., RefPtr 0, rest
       Call L1                              0, CodePtr f1, RefPtr 0, ..., RefPtr 0, rest
       ?
       ...      (* function 1 body *)
       Pops ?   (* delete local variables and env *)
       Load 1
       Store n+2(* replace closure with return pointer *)
       Pops n+1 (* delete arguments *)
       Return
   L1: Call L2                              0, CodePtr f2, CodePtr f1, RefPtrs, rest
       ?
       ...      (* function 2 body *)
       Return
   L2: Call L3
       ?
       ...      (* more function bodies *)
   ...
       Return
   LK: Call L
       ...
       Return   (* end of last function *)
   L:  Pop                                  CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Load ?   (* copy code pointer for function 1 *)
       Load ?   (* copy free mutrec vars for function 1 *)
       Load ?   (* copy free vars for function 1 *)
       ...                                  vm1, ..., v1, RefPtr 0, ..., RefPtr 0, CodePtr f1, CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Cons 0 (m1 + n1)
       Cons 0 2                             Block 0 [CodePtr f1; Block 0 Env], CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Store ?                              CodePtr fk, ..., CodePtr f2, f1, RefPtrs, rest
       Load ?   (* copy code pointer for function 2 *)
       Load ?   (* copy free mutrec vars for function k-1 *)
       Load ?   (* copy free vars for function k-1 *)
       ...
       Cons 0 (m2 + n2)
       Cons 0 2                             
       Store ?                              CodePtr fk, ..., CodePtr f3, f2, f1, RefPtrs, rest
       ...                                  fk, ..., f2, f1, RefPtrs, rest
       Load ?
       Load 1                               fk, RefPtr 0, fk, f(k-1), ..., RefPtrs, rest
       Update                               fk, f(k-1), ..., f1, RefPtrs, rest
       Load ?
       Load 2
       Update
       ...      (* update RefPtrs with closures *)
       Store ?  (* pop RefPtrs *)           fk, f(k-1), ..., f1, rest
       ...
  *)
  (*
   * - push refptrs and leading 0
   * - for each function (in order), push a Call 0, remember the next label,
   *   calculate its environment, remember the environment, compile its body in
   *   that environment
   * - update Calls
   * - for each environment emit code to load that
   *   environment and build the closure
   * - update refptrs, etc.
   *)
  let (nr,ns) = (case nso of NONE => (0,[]) | SOME ns => (LENGTH ns,ns) ) in
  let s = FOLDL (\ s _n . incsz (emit s [Stack (PushInt i0); Ref])) s ns in
  let s = emit s [Stack (PushInt i0)] in
  let (s,k,labs,ecs) = FOLDL
    (\ (s,k,labs,ecs) (xs,e) .
      let az = LENGTH xs in
      let lab = s.next_label in
      let s = emit s [Call 0] in
      let j = LENGTH s.code in
      let fvs = free_vars e in
      let (bind_fv (n,env,ec) fv =
        (case find_index fv xs 1 of
          SOME j => (n, FUPDATE  env ( fv, (CTArg (2 + az - j))), ec)
        | NONE => (case find_index fv ns 0 of
            NONE => (n+1, FUPDATE  env ( fv, (CTEnv n)), (CEEnv fv::ec))
          | SOME j => if j = k
                      then (n, FUPDATE  env ( fv, (CTArg (2 + az))), ec)
                      else (n+1, FUPDATE  env ( fv, (CTRef n)), (CERef j)::ec)
          )
        )) in
      let (n,env,ec) = num_set_foldl bind_fv (0,FEMPTY,[]) fvs in
      let s' =  s with<| env := env; sz := 0; decl := NONE; tail := SOME (az,0) |> in
      let s' = compile s' e in
      let n = (case s'.tail of NONE => 1 | SOME (j,k) => k+1 ) in
      let s' = emit s' [Stack (Pops n);
                        Stack (Load 1);
                        Stack (Store (az+2));
                        Stack (Pops (az+1));
                        Return] in
      let s =  s' with<| env := s.env; sz := s.sz + 1; decl := s.decl; tail := s.tail |> in
      (s,k+1,(j,lab)::labs,ec::ecs))
    (s,0,[],[]) defs in
  let s =  s with<| code :=
    replace_calls (LENGTH s.code) ((0,s.next_label)::labs) s.code |> in
  let s = emit s [Stack Pop] in
  let nk = LENGTH defs in
  let (s,k) = FOLDL
    (\ (s,k) ec .
      let s = incsz (emit s [Stack (Load (nk - k))]) in
      let s = FOLDR  emit_ec  s  ec in
      let j = LENGTH ec in
      let s = emit s [Stack (if j = 0 then PushInt i0 else Cons 0 j)] in
      let s = emit s [Stack (Cons 0 2)] in
      let s = decsz (emit s [Stack (Store (nk - k))]) in
      let s =  s with<| sz := s.sz - j |> in
      (s,k+1))
    (s,1) ecs in
  let (s,k) = FOLDL
    (\ (s,k) _n .
      let s = emit s [Stack (Load (nk + nk - k))] in
      let s = emit s [Stack (Load (nk + 1 - k))] in
      let s = emit s [Update] in
      (s,k+1))
    (s,1) ns in
  let k = nk - 1 in
  FOLDL
    (\ s _n . decsz (emit s [Stack (Store k)]))
         s ns)`;

val _ = Defn.save_defn compile_defn;

val _ = Hol_datatype `
 nt =
    NTvar of num
  | NTapp of nt list => typeN
  | NTfn
  | NTnum
  | NTbool`;


 val t_to_nt_defn = Hol_defn "t_to_nt" `

(t_to_nt a (Tvar x) = (case find_index x a 0 of SOME n => NTvar n ))
/\
(t_to_nt a (Tapp ts tn) = NTapp (MAP (t_to_nt a) ts) tn)
/\
(t_to_nt a (Tfn _ _) = NTfn)
/\
(t_to_nt a Tnum = NTnum)
/\
(t_to_nt a Tbool = NTbool)`;

val _ = Defn.save_defn t_to_nt_defn;

val _ = Hol_datatype `
 repl_state =
  <| cmap : (conN, num) fmap
   ; cpam : (typeN, (num, conN # nt list) fmap) fmap
   ; vmap : (varN, num) fmap
   ; vpam : (num, varN) fmap
   ; nextv : num
   ; cs : compiler_state
   |>`;


val _ = Define `
 init_compiler_state =
  <| env := FEMPTY
   ; code := []
   ; next_label := 1 (* depends on exception handlers *)
   ; sz := 0
   ; inst_length := \ i . 0 (* TODO: depends on runtime *)
   ; decl := NONE
   ; tail := NONE
   |>`;


val _ = Define `
 init_repl_state =
  <| cmap := FEMPTY
   ; cpam := FEMPTY
   ; vmap := FEMPTY
   ; vpam := FEMPTY
   ; nextv := 0
   ; cs := init_compiler_state
   |>`;


val _ = Define `
 (compile_exp d rs e =
  let e = remove_Gt_Geq e in
  let e = remove_mat_exp e in
  let (s,Ce) = exp_to_Cexp d rs.cmap (<|m := rs.vmap; w := rs.vpam; n := rs.nextv|>, e) in
  let Ce = remove_mat Ce in
  let decl = (case d of NONE => NONE
             | SOME vs =>
                 SOME (rs.cs.env, rs.cs.sz, IMAGE (\ v . FAPPLY  s.m  v) vs)
             ) in
  let cs = compile (rs.cs with<| decl := decl |>) Ce in (* parens: Lem sucks *)
   rs with<| vmap := s.m; vpam := s.w; nextv := s.n; cs := cs |>)`;


(* TODO: typechecking *)
(* TODO: printing *)

 val pat_vars_defn = Hol_defn "pat_vars" `

(pat_vars (Pvar v) = {v})
/\
(pat_vars (Plit _) = {})
/\
(pat_vars (Pcon _ ps) = FOLDL (\ s p . s UNION pat_vars p) {} ps)`;

val _ = Defn.save_defn pat_vars_defn;

 val number_constructors_defn = Hol_defn "number_constructors" `

(number_constructors a (cm,cw) (n:num) [] = (cm,cw))
/\
(number_constructors a (cm,cw) n ((c,tys)::cs) =
  let cm' = FUPDATE  cm ( c, n) in
  let cw' = FUPDATE  cw ( n, (c, MAP (t_to_nt a) tys)) in
  number_constructors a (cm',cw') (n+1) cs)`;

val _ = Defn.save_defn number_constructors_defn;

 val repl_dec_defn = Hol_defn "repl_dec" `

(repl_dec rs (Dtype []) = rs)
/\
(repl_dec rs (Dtype ((a,ty,cs)::ts)) =
  let (cm,cw) = number_constructors a (rs.cmap,FEMPTY) 0 cs in
  repl_dec ( rs with<| cmap := cm; cpam := FUPDATE  rs.cpam ( ty, cw) |>) (Dtype ts)) (* parens: Lem sucks *)
/\
(repl_dec rs (Dletrec defs) =
  compile_exp (SOME (LIST_TO_SET (MAP ( \x . (case x of (v,_,_) => v)) defs)))
    rs (Letrec defs (Var "")))
/\
(repl_dec rs (Dlet p e) =
  compile_exp (SOME (pat_vars p)) rs (Mat e [(p,Var "")]))`;

val _ = Defn.save_defn repl_dec_defn;

val _ = Define `
 repl_exp = compile_exp NONE`;


val _ = Define `
 (lookup_conv_ty m ty n = FAPPLY  (FAPPLY  m  ty)  n)`;


 val inst_arg_defn = Hol_defn "inst_arg" `

(inst_arg tvs (NTvar n) = EL  n  tvs)
/\
(inst_arg tvs (NTapp ts tn) = NTapp (MAP (inst_arg tvs) ts) tn)
/\
(inst_arg tvs tt = tt)`;

val _ = Defn.save_defn inst_arg_defn;

 val bcv_to_v_defn = Hol_defn "bcv_to_v" `

(bcv_to_v m (NTnum, Number i) = Lit (IntLit i))
/\
(bcv_to_v m (NTbool, Number i) =
  if i = bool_to_int T then Lit (Bool T) else
    if i = bool_to_int F then Lit (Bool F) else
      Recclosure [] [] "Fail: Number")
/\
(bcv_to_v m (NTapp _ ty, Number i) =
  Conv (FST (lookup_conv_ty m ty (Num i))) [])
/\
(bcv_to_v m (_, Number _) = Recclosure [] [] "Fail: Number")
/\
(bcv_to_v m (NTapp tvs ty, Block n vs) =
  let (tag, args) = lookup_conv_ty m ty n in
  let args = MAP (inst_arg tvs) args in
  if LENGTH args = LENGTH vs then
  Conv tag
    (MAP (\ (ty,v) . bcv_to_v m (ty,v)) (ZIP ( args, vs)))
    (* can't use map2 because no congruence theorem (for termination) *)
    (* thus this remains uncurried *)
    (* also, uneta: Hol_defn sucks *)
  else Recclosure [] [] "Fail: Block")
/\
(bcv_to_v m (NTfn, Block 0 _) =Closure [] "" (Var ""))
/\
(bcv_to_v m (_, Block _ _) = Recclosure [] [] "Fail: Block")
/\
(bcv_to_v m (_, CodePtr _) = Recclosure [] [] "Fail: CodePtr")
/\
(bcv_to_v m (_, RefPtr _) = Recclosure [] [] "Fail: RefPtr")`;

val _ = Defn.save_defn bcv_to_v_defn;


(* Constant folding
val fold_consts : exp -> exp

let rec
fold_consts (Raise err) = Raise err
and
fold_consts (Val v) = Val (v_fold_consts v)
and
fold_consts (Con c es) = Con c (List.map fold_consts es)
and
fold_consts (Var vn) = Var vn
and
fold_consts (Fun vn e) = Fun vn (fold_consts e)
and
fold_consts (App (Opn opn) (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (IntLit (opn_lookup opn n1 n2)))
and
fold_consts (App (Opb opb) (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (Bool (opb_lookup opb n1 n2)))
and
fold_consts (App Equality (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (Bool (n1 = n2)))
and
fold_consts (App Equality (Val (Lit (Bool b1))) (Val (Lit (Bool b2)))) =
  Val (Lit (Bool (b1 = b2)))
and
fold_consts (App op e1 e2) =
  let e1' = fold_consts e1 in
  let e2' = fold_consts e2 in
  if e1 = e1' && e2 = e2' then (App op e1 e2) else
  fold_consts (App op e1' e2')
and
fold_consts (Log And (Val (Lit (Bool true))) e2) =
  fold_consts e2
and
fold_consts (Log Or (Val (Lit (Bool false))) e2) =
  fold_consts e2
and
fold_consts (Log _ (Val (Lit (Bool b))) _) =
  Val (Lit (Bool b))
and
fold_consts (Log log e1 e2) =
  Log log (fold_consts e1) (fold_consts e2)
and
fold_consts (If (Val (Lit (Bool b))) e2 e3) =
  if b then fold_consts e2 else fold_consts e3
and
fold_consts (If e1 e2 e3) =
  If (fold_consts e1) (fold_consts e2) (fold_consts e3)
and
fold_consts (Mat (Val v) pes) =
  fold_match v pes
and
fold_consts (Mat e pes) =
  Mat (fold_consts e) (match_fold_consts pes)
and
fold_consts (Let vn e1 e2) =
  Let vn (fold_consts e1) (fold_consts e2)
and
fold_consts (Letrec funs e) =
  Letrec (funs_fold_consts funs) (fold_consts e)
and
fold_consts (Proj (Val (Conv None vs)) n) =
  Val (List.nth vs n)
and
fold_consts (Proj e n) = Proj (fold_consts e) n
and
v_fold_consts (Lit l) = Lit l
and
v_fold_consts (Conv None vs) =
  Conv None (List.map v_fold_consts vs)
and
v_fold_consts (Closure envE vn e) =
  Closure (env_fold_consts envE) vn (fold_consts e)
and
v_fold_consts (Recclosure envE funs vn) =
  Recclosure (env_fold_consts envE) (funs_fold_consts funs) vn
and
env_fold_consts [] = []
and
env_fold_consts ((vn,v)::env) =
  ((vn, v_fold_consts v)::env_fold_consts env)
and
funs_fold_consts [] = []
and
funs_fold_consts ((vn1,vn2,e)::funs) =
  ((vn1,vn2,fold_consts e)::funs_fold_consts funs)
and
match_fold_consts [] = []
and
match_fold_consts ((p,e)::pes) =
  (p, fold_consts e)::match_fold_consts pes
and
fold_match v [] = Raise Bind_error
and
fold_match (Lit l) ((Plit l',e)::pes) =
  if l = l' then
    fold_consts e
  else
    fold_match (Lit l) pes
and
(* TODO: fold more pattern matching (e.g. to Let)? Need envC? *)
fold_match v pes =
  Mat (Val v) (match_fold_consts pes)
*)
val _ = export_theory()

