(*---------------------------------------------------------------------------
                Parsing datatype specifications

   The grammar we're parsing is:

       G ::=              id "=" <form>
       form ::=           <phrase> ( "|" <phrase> ) *  |  <record_defn>
       phrase ::=         id  | id "of" <under_constr>
       under_constr ::=   <ptype> ( "=>" <ptype> ) * | <record_defn>
       record_defn ::=    "<|"  <idtype_pairs> "|>"
       idtype_pairs ::=   id ":" <type> | id : <type> ";" <idtype_pairs>
       ptype ::=          <type> | "(" <type> ")"

  It had better be the case that => is not a type infix.  This is true of
  the standard HOL distribution.  In the event that => is an infix, this
  code will still work as long as the input puts the types in parentheses.
 ---------------------------------------------------------------------------*)

structure ParseDatatype :> ParseDatatype =
struct

 type tyname   = string

 open HolKernel Abbrev optmonad monadic_parse fragstr;
 infix >> >- >-> ++

val ERR = mk_HOL_ERR "ParseDatatype";


datatype pretype
   = dVartype of string
   | dTyop of {Tyop : string, Thy : string option, Args : pretype list}
   | dAQ of Type.hol_type

type field = string * pretype
type constructor = string * pretype list

datatype datatypeForm
   = Constructors of constructor list
   | Record of field list

type AST = tyname * datatypeForm

fun pretypeToType pty =
  case pty of
    dVartype s => Type.mk_vartype s
  | dTyop {Tyop = s, Thy, Args} => let
    in
      case Thy of
        NONE => Type.mk_type(s, map pretypeToType Args)
      | SOME t => Type.mk_thy_type{Tyop = s, Thy = t,
                                   Args = map pretypeToType Args}
    end
  | dAQ pty => pty

fun ident0 s = let
  open HOLtokens
  infix OR
in
  (itemP Char.isAlpha >-                         (fn char1 =>
   many_charP (Char.isAlphaNum OR ITEMS "_'") >- (fn rest =>
   return (str char1 ^ rest)))) s
end
fun ident s = token ident0 s

fun qtyop {Tyop, Thy, Args} = dTyop {Tyop = Tyop, Thy = SOME Thy, Args = Args}
fun tyop (s, args) = dTyop {Tyop = s, Thy = NONE, Args = args}

fun parse_type strm =
  parse_type.parse_type {vartype = dVartype, tyop = tyop, qtyop = qtyop,
                         antiq = dAQ} true
  (Parse.type_grammar()) strm

fun parse_constructor_id s =
  (token (many1_charP (fn c => Lexis.in_class (Lexis.hol_symbols, Char.ord c)))
   ++
   ident) s

val parse_record_fld =
  ident >-
  (fn fldname => symbol ":" >>
   parse_type >-
   (fn pty => return (fldname, pty)))

val parse_record_defn =
  (symbol "<|" >> sepby1 (symbol ";") parse_record_fld >-> symbol "|>")

val parse_phrase =
  parse_constructor_id >-                            (fn constr_id =>
  optional (symbol "of" >> sepby1 (symbol "=>") parse_type) >- (fn optargs =>
  case optargs of
    NONE => return (constr_id, [])
  | SOME args => return (constr_id, args)))

val parse_form =
  (parse_record_defn >- return o Record) ++
  (sepby1 (symbol "|") parse_phrase >-  return o Constructors)

val parse_G =
  ident >-                                           (fn tyname =>
  symbol "=" >> parse_form >-                        (fn form =>
  return (tyname, form)))

fun fragtoString (QUOTE s) = s
  | fragtoString (ANTIQUOTE _) = " ^... "

fun quotetoString [] = ""
  | quotetoString (x::xs) = fragtoString x ^ quotetoString xs

fun parse strm =
  case fragstr.parse (sepby1 (symbol ";") parse_G) strm
   of (strm, SOME result) => result
    | (strm, NONE) => raise ERR "parse"
          ("Parse failed with input remaining: "^quotetoString strm)


(*---------------------------------------------------------------------------
          tests

quotation := true;

parse `foo = NIL | CONS of 'a => 'a foo`;
parse `list = NIL | :: of 'a => list`;
parse `void = Void`;
parse `pair = CONST of 'a#'b`;
parse `onetest = OOOO of one`;
parse `tri = Hi | Lo | Fl`;
parse `iso = ISO of 'a`;
parse `ty = C1 of 'a
          | C2
          | C3 of 'a => 'b => ty
          | C4 of ty => 'c => ty => 'a => 'b
          | C5 of ty => ty`;
parse `bintree = LEAF of 'a | TREE of bintree => bintree`;
parse `typ = C of one
                  => (one#one)
                  => (one -> one -> 'a list)
                  => ('a,one#one,'a list) ty`;
parse `Typ = D of one
                  # (one#one)
                  # (one -> one -> 'a list)
                  # ('a, one#one, 'a list) ty`;

parse `atexp = var_exp of var
           | let_exp of dec => exp ;

       exp = aexp    of atexp
           | app_exp of exp => atexp
           | fn_exp  of match ;

     match = match  of rule
           | matchl of rule => match ;

      rule = rule of pat => exp ;

       dec = val_dec   of valbind
           | local_dec of dec => dec
           | seq_dec   of dec => dec ;

   valbind = bind  of pat => exp
           | bindl of pat => exp => valbind
           | rec_bind of valbind ;

       pat = wild_pat
           | var_pat of var`;

val state = Type`:ind->bool`;
val nexp  = Type`:^state -> ind`;
val bexp  = Type`:^state -> bool`;

parse `comm = skip
            | :=    of bool list => ^nexp
            | ;;    of comm => comm
            | if    of ^bexp => comm => comm
            | while of ^bexp => comm`;

parse `ascii = ASCII of bool=>bool=>bool=>bool=>bool=>bool=>bool=>bool`;
*)


end;
