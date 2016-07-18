structure mp_then =
struct

local
  open HolKernel Drule Parse boolSyntax

fun avSPEC_ALL avds th =
  let
    fun recurse avds acc th =
      case Lib.total dest_forall (concl th) of
          SOME (v,bod) =>
          let
            val v' = variant avds v
          in
            recurse (v'::avds) (v'::acc) (SPEC v' th)
          end
        | NONE => (List.rev acc, th)
  in
    recurse avds [] th
  end

fun PART_MATCH' f th t =
  let
    val (vs, _) = strip_forall (concl th)
    val hypfvs_set = hyp_frees th
    val hypfvs = HOLset.listItems hypfvs_set
    val tfvs = free_vars t
    val dontspec = union tfvs hypfvs
    val (vs, speccedth) = avSPEC_ALL dontspec th
    val ((tmsig,_),_) = raw_match [] hypfvs_set (f (concl speccedth)) t ([],[])
    val dontgen = union (map #redex tmsig) dontspec
  in
    GENL (set_diff vs dontgen) (INST tmsig speccedth)
  end

fun match_subterm pat =
  can (find_term (can (match_term pat)))



in

datatype match_position =
  Any
| Pat of term quotation
| Pos of (term list -> term)
| Concl

fun mp_then pos (ttac : thm_tactic) ith0 rth (g as (asl,w)) =
  let
    val ith = MP_CANON ith0
    fun m f k t =
      let
        val th = PART_MATCH' f ith t
      in
        ttac th g
      end handle HOL_ERR _ => k()
    fun conj f t = t |> dest_imp |> #1 |> strip_conj |> f
    val max = ith |> concl |> strip_forall |> #2 |> conj length
    val fail = mk_HOL_ERR "mp_then" "mp_then" "No match"
    val t = concl rth
  in
    case pos of
        Any =>
        let
          fun doit (n:int) =
            if n > max then raise fail
            else m (conj (el n)) (fn _ => doit (n + 1)) t
        in
          doit 1
        end
      | Pos f => m (conj f) (fn _ => raise fail) t
      | Pat q =>
        let
          val pat = parse_in_context
                      (HOLset.listItems (FVL (w::asl) empty_tmset))
                      q
          fun doit n =
            if n > max then raise fail
            else m (fn t => let val subterm = conj (el n) t
                            in
                              if can (match_subterm pat) subterm then
                                subterm
                              else raise fail
                            end)
                   (fn _ => doit (n + 1))
                   t
        in
          doit 1
        end
      | Concl => m (fn t => t |> dest_imp |> #2)
                   (fn _ => raise fail)
                   (dest_neg t handle HOL_ERR _ => mk_neg t)
  end

end (* local *)

end