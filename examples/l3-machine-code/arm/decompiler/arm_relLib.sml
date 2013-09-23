structure arm_relLib =
struct

open HolKernel Parse boolLib bossLib Lib
open armTheory armLib arm_stepTheory pred_setTheory pairTheory optionTheory
open arithmeticTheory wordsTheory wordsLib addressTheory combinTheory pairSyntax
open sumTheory whileTheory

open arm_relTheory progTheory helperLib arm_decompLib

local

val ERR = Feedback.mk_HOL_ERR "arm_relLib"

val cond_var = mk_var ("cond", ``:bool``)
val r15 = mk_var ("r15", ``:word32``)

val (spec,_,_,_) = arm_decompLib.l3_arm_tools

val arm_assert =
   ARM_ASSERT_def
   |> SPEC_ALL
   |> REWRITE_RULE [arm_FP_REGS_def]
   |> Conv.CONV_RULE (Conv.RHS_CONV helperLib.STAR_AC_CONV)
   |> GSYM

val targets = progSyntax.strip_star (utilsLib.lhsc arm_assert)
val fv_spec_tm = free_vars (Thm.concl arm_assert)

val precond_thm = Q.prove(
   `!b. precond b = cond (Abbrev b): 'a set set`,
   SIMP_TAC std_ss [markerTheory.Abbrev_def,set_sepTheory.precond_def])

fun add_prime v = mk_var (fst (dest_var v) ^ "'", type_of v)

val PAIR_LEMMA = Q.prove(
   `((x1 = y1) ==> (x2 = y2) ==> b) ==> (((x2,x1) = (y2:'a,y1:'b)) ==> b)`,
   SIMP_TAC std_ss [])

fun find_match [] tm = fail()
  | find_match (x::xs) tm = match_term x tm handle HOL_ERR _ => find_match xs tm

fun first_r_eq x = rand o Lib.first (equal (rator x) o rator)

fun is_NONE x = not (Option.isSome x)

val ARM_ASSERT_INTRO_CONV = STAR_AC_CONV THENC Conv.REWR_CONV arm_assert

val UPDATE_CONV =
   Conv.DEPTH_CONV (updateLib.UPDATE_APPLY_CONV (wordsLib.word_EQ_CONV))
   THENC STAR_AC_CONV

fun FORCE_DISCH_ALL thm =
   (if List.null (Thm.hyp thm) then DISCH boolSyntax.T else DISCH_ALL) thm

val INTRO_TRIPLE_RULE =
   REWRITE_RULE [] o
   SPEC cond_var o
   MATCH_MP INTRO_TRIPLE_L3_ARM o
   FORCE_DISCH_ALL

(* abbreviate posts *)
fun abbrev_conv ignore pat post =
  if ignore pat
     then ALL_CONV post
  else if is_var pat
     then if pat = post
             then ALL_CONV post
          else ASSUME (mk_eq (post, add_prime pat))
  else if is_comb pat
     then (RAND_CONV (abbrev_conv ignore (rand pat))
           THENC RATOR_CONV (abbrev_conv ignore (rator pat))) post
  else if pat = post
     then ALL_CONV post
  else NO_CONV post

fun old_to_new th =
   let
      val th =
         th |> SIMP_RULE (std_ss++sep_cond_ss) [precond_thm]
            |> REWRITE_RULE [SPEC_MOVE_COND]
            |> UNDISCH_ALL
      val fnd =
         find_match (progSyntax.strip_star (progSyntax.dest_pre (Thm.concl th)))
      val frame = progSyntax.list_mk_star (List.filter (not o can fnd) targets)
      val xs = List.concat (List.mapPartial (Lib.total (fst o fnd)) targets)
      val th =
         th |> INST xs
            |> SPECC_FRAME_RULE frame
            |> Conv.CONV_RULE (PRE_CONV ARM_ASSERT_INTRO_CONV)
      val ps = progSyntax.strip_star (progSyntax.dest_post (Thm.concl th))
      val (simple, rest) =
         targets |> Lib.filter (fn tm => not (Lib.mem tm ps))
                 |> List.map (fn x => (first_r_eq x targets, first_r_eq x ps))
                 |> List.partition (is_var o fst)
      val ts =
         List.map
            (fn (x, y) => (rator x, combinSyntax.mk_update (rand x,y))) rest
      val fs = Lib.mk_set (map (rator o fst) rest)
      val all =
         simple @
         map (fn f =>
                let
                   val ups = List.filter (Lib.equal f o fst) ts |> map snd
                   val t = List.foldr Term.mk_comb f ups
                in
                   (f, t)
                end) fs
      val lemma = arm_assert
                  |> INST (List.map (op |->) all)
                  |> Conv.CONV_RULE (Conv.LAND_CONV UPDATE_CONV)
      val th =
         th |> Conv.CONV_RULE
                  (POST_CONV (STAR_AC_CONV THENC Conv.REWR_CONV lemma))
            |> INTRO_TRIPLE_RULE
      val pat = th |> concl |> rator |> rator |> rand
   in
      th |> CONV_RULE (RAND_CONV (abbrev_conv (Lib.equal r15) pat))
         |> DISCH_ALL
         |> repeat (MATCH_MP PAIR_LEMMA)
         |> UNDISCH_ALL
   end

in

val l3_triple =
   (* cache *)
     (fn hex =>
         (case spec hex of
             ((th1,x1,y1 as SOME _), NONE) => ((old_to_new th1,x1,y1), NONE)
           | ((th1,x1,y1 as SOME _), SOME (th2,x2,y2)) =>
                 ((old_to_new th1,x1,y1), SOME (old_to_new th2,x2,y2))
           | _ => fail())
         handle HOL_ERR _ => raise ERR "l3_triple" hex)

val (swap_primes,SWAP_PRIMES_RULE) = let
  val vs = (cond_var :: fv_spec_tm) |> map (fn v => (v,add_prime v))
  val ss = map (fn (x,y) => x |-> y) vs @ map (fn (x,y) => y |-> x) vs
  in (subst ss, INST ss) end

end

end
