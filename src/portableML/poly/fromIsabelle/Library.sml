structure Library =
struct
local open Portable in
  fun member eq list x =
    let
      fun memb [] = false
        | memb (y :: ys) = eq (x, y) orelse memb ys;
    in memb list end;
  fun remove eq x xs = if member eq xs x then
                         List.filter (fn y => not (eq (x, y))) xs
                       else xs;
  fun update eq x xs = cons x (remove eq x xs);
  fun insert eq x xs = if member eq xs x then xs else x :: xs;
  fun merge eq (xs, ys) =
    if null xs then ys else foldr' (insert eq) ys xs;
  val map_filter = List.mapPartial;
  fun (b ? f) = if b then f else fn x => x
  fun enclose lpar rpar str = lpar ^ str ^ rpar;
  fun filter_out P = List.filter (not o P)
  fun fold2 _ [] [] z = z
    | fold2 f (x :: xs) (y :: ys) z = fold2 f xs ys (f x y z)
    | fold2 _ _ _ _ = raise ListPair.UnequalLengths;
  fun fold_product f _ [] z = z
    | fold_product f [] _ z = z
    | fold_product f (x :: xs) ys z =
        z |> foldl' (f x) ys |> fold_product f xs ys

  fun single x = [x]
  fun the_single [x] = x
    | the_single _ = raise List.Empty;
  fun singleton f x = the_single (f [x])

end (* local *)
end;
