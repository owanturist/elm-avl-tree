module AVL exposing
    ( AVL
    , empty, singleton, fromList
    , keys, values, toList
    , insert, remove, update
    , isEmpty, size, member, get
    , map, filter, partition, foldl, foldr
    , union, diff, intersect, merge
    )

{-| An AVL Tree based dictionary.


# Dictionary

@docs AVL


# Construction

@docs empty, singleton, fromList


# Deconstruct

@docs keys, values, toList


# Manipulation

@docs insert, remove, update


# Query

@docs isEmpty, size, member, get


# Transform

@docs map, filter, partition, foldl, foldr


# Combine

@docs union, diff, intersect, merge

-}

import Internal exposing (Node(..))


{-| -}
type alias AVL key value =
    Internal.AVL key value



-- U T I L S


height : Node key value -> Int
height node =
    case node of
        RBEmpty_elm_builtin ->
            0

        RBNode_elm_builtin h _ _ _ _ ->
            h


nil : Node key value
nil =
    RBEmpty_elm_builtin


leaf : key -> value -> Node key value -> Node key value -> Node key value
leaf key value left right =
    RBNode_elm_builtin (1 + max (height left) (height right)) key value left right


untuple : ( Int, Node key value ) -> AVL key value
untuple ( count, root ) =
    Internal.AVL count root



-- C O N S T R U C T I O N


{-| -}
empty : AVL comparable value
empty =
    Internal.AVL 0 nil


{-| -}
singleton : comparable -> value -> AVL comparable value
singleton key value =
    Internal.AVL 1 (RBNode_elm_builtin 1 key value nil nil)


{-| -}
fromList : List ( comparable, value ) -> AVL comparable value
fromList list =
    untuple (List.foldl fromListHelper ( 0, nil ) list)


fromListHelper : ( comparable, value ) -> ( Int, Node comparable value ) -> ( Int, Node comparable value )
fromListHelper ( key, value ) ( count, root ) =
    let
        ( added, nextRoot ) =
            insertHelp key value root
    in
    if added then
        ( count + 1, nextRoot )

    else
        ( count, nextRoot )



-- D E C O N S T R U C T


{-| -}
keys : AVL key value -> List key
keys avl =
    let
        step : key -> value -> List key -> List key
        step key _ acc =
            key :: acc
    in
    foldr step [] avl


{-| -}
values : AVL key value -> List value
values avl =
    let
        step : key -> value -> List value -> List value
        step _ value acc =
            value :: acc
    in
    foldr step [] avl


{-| -}
toList : AVL key value -> List ( key, value )
toList avl =
    let
        step : key -> value -> List ( key, value ) -> List ( key, value )
        step key value acc =
            ( key, value ) :: acc
    in
    foldr step [] avl



-- M A N I P U L A T I O N


{-| -}
insert : comparable -> value -> AVL comparable value -> AVL comparable value
insert key value (Internal.AVL count root) =
    let
        ( added, nextRoot ) =
            insertHelp key value root
    in
    if added then
        Internal.AVL (count + 1) nextRoot

    else
        Internal.AVL count nextRoot


insertHelp : comparable -> value -> Node comparable value -> ( Bool, Node comparable value )
insertHelp key value node =
    case node of
        RBEmpty_elm_builtin ->
            ( True
            , RBNode_elm_builtin 1 key value nil nil
            )

        RBNode_elm_builtin h k v l r ->
            case compare key k of
                LT ->
                    let
                        ( added, nextL ) =
                            insertHelp key value l
                    in
                    ( added, balance k v nextL r )

                GT ->
                    let
                        ( added, nextR ) =
                            insertHelp key value r
                    in
                    ( added, balance k v l nextR )

                EQ ->
                    ( False
                    , RBNode_elm_builtin h key value l r
                    )


balance : key -> value -> Node key value -> Node key value -> Node key value
balance pk pv pl pr =
    case ( pl, pr ) of
        ( RBEmpty_elm_builtin, RBEmpty_elm_builtin ) ->
            RBNode_elm_builtin 1 pk pv nil nil

        ( RBNode_elm_builtin lh lk lv ll lr, RBEmpty_elm_builtin ) ->
            if lh > 1 then
                rotateRight pk pv lk lv ll lr pr

            else
                RBNode_elm_builtin (1 + lh) pk pv pl pr

        ( RBEmpty_elm_builtin, RBNode_elm_builtin rh rk rv rl rr ) ->
            if rh > 1 then
                rotateLeft pk pv pl rk rv rl rr

            else
                RBNode_elm_builtin (1 + rh) pk pv pl pr

        ( RBNode_elm_builtin lh lk lv ll lr, RBNode_elm_builtin rh rk rv rl rr ) ->
            if lh - rh < -1 then
                rotateLeft pk pv pl rk rv rl rr

            else if lh - rh > 1 then
                rotateRight pk pv lk lv ll lr pr

            else
                RBNode_elm_builtin (1 + max lh rh) pk pv pl pr


rotateLeft : key -> value -> Node key value -> key -> value -> Node key value -> Node key value -> Node key value
rotateLeft pk pv pl rk rv rl rr =
    case rl of
        RBEmpty_elm_builtin ->
            leaf rk rv (RBNode_elm_builtin (1 + height pl) pk pv pl nil) rr

        RBNode_elm_builtin lh lk lv ll lr ->
            if lh > height rr then
                leaf lk lv (leaf pk pv pl ll) (leaf rk rv lr rr)

            else
                leaf rk rv (leaf pk pv pl rl) rr


rotateRight : key -> value -> key -> value -> Node key value -> Node key value -> Node key value -> Node key value
rotateRight pk pv lk lv ll lr pr =
    case lr of
        RBEmpty_elm_builtin ->
            leaf lk lv ll (RBNode_elm_builtin (1 + height pr) pk pv nil pr)

        RBNode_elm_builtin rh rk rv rl rr ->
            if height ll < rh then
                leaf rk rv (leaf lk lv ll rl) (leaf pk pv rr pr)

            else
                leaf lk lv ll (leaf pk pv lr pr)


{-| -}
remove : comparable -> AVL comparable value -> AVL comparable value
remove key ((Internal.AVL count root) as avl) =
    case removeHelp key root of
        Nothing ->
            avl

        Just nextRoot ->
            Internal.AVL (count - 1) nextRoot


removeHelp : comparable -> Node comparable value -> Maybe (Node comparable value)
removeHelp key node =
    case node of
        RBEmpty_elm_builtin ->
            Nothing

        RBNode_elm_builtin _ k v l r ->
            case compare key k of
                LT ->
                    Maybe.map (\nextL -> balance k v nextL r) (removeHelp key l)

                GT ->
                    Maybe.map (balance k v l) (removeHelp key r)

                EQ ->
                    if height l < height r then
                        case removeMin r of
                            Nothing ->
                                Just l

                            Just ( minK, minV, nextR ) ->
                                Just (leaf minK minV l nextR)

                    else
                        case removeMax l of
                            Nothing ->
                                Just r

                            Just ( maxK, maxV, nextL ) ->
                                Just (leaf maxK maxV nextL r)


removeMin : Node key value -> Maybe ( key, value, Node key value )
removeMin node =
    case node of
        RBEmpty_elm_builtin ->
            Nothing

        RBNode_elm_builtin _ k v l r ->
            case removeMin l of
                Nothing ->
                    Just ( k, v, r )

                Just ( rk, rv, nextL ) ->
                    Just ( rk, rv, balance k v nextL r )


removeMax : Node key value -> Maybe ( key, value, Node key value )
removeMax node =
    case node of
        RBEmpty_elm_builtin ->
            Nothing

        RBNode_elm_builtin _ k v l r ->
            case removeMax r of
                Nothing ->
                    Just ( k, v, l )

                Just ( rk, rv, nextR ) ->
                    Just ( rk, rv, balance k v l nextR )


{-| -}
update : comparable -> (Maybe value -> Maybe value) -> AVL comparable value -> AVL comparable value
update key transform avl =
    case get key avl of
        Nothing ->
            case transform Nothing of
                Nothing ->
                    avl

                Just value ->
                    insert key value avl

        just ->
            case transform just of
                Nothing ->
                    remove key avl

                Just value ->
                    insert key value avl



-- Q U E R Y


{-| -}
isEmpty : AVL key value -> Bool
isEmpty avl =
    size avl == 0


{-| -}
size : AVL key value -> Int
size (Internal.AVL count _) =
    count


{-| -}
member : comparable -> AVL comparable value -> Bool
member key avl =
    get key avl /= Nothing


{-| -}
get : comparable -> AVL comparable value -> Maybe value
get key (Internal.AVL _ root) =
    getHelper key root


getHelper : comparable -> Node comparable value -> Maybe value
getHelper target node =
    case node of
        RBEmpty_elm_builtin ->
            Nothing

        RBNode_elm_builtin _ key value left right ->
            case compare target key of
                LT ->
                    getHelper target left

                GT ->
                    getHelper target right

                EQ ->
                    Just value



-- T R A N S F O R M


{-| -}
map : (key -> a -> b) -> AVL key a -> AVL key b
map fn (Internal.AVL count root) =
    Internal.AVL count (mapHelp fn root)


mapHelp : (key -> a -> b) -> Node key a -> Node key b
mapHelp fn node =
    case node of
        RBEmpty_elm_builtin ->
            RBEmpty_elm_builtin

        RBNode_elm_builtin h k v l r ->
            RBNode_elm_builtin h k (fn k v) (mapHelp fn l) (mapHelp fn r)


{-| -}
filter : (comparable -> value -> Bool) -> AVL comparable value -> AVL comparable value
filter check avl =
    let
        step : comparable -> value -> ( Int, Node comparable value ) -> ( Int, Node comparable value )
        step key value (( count, root ) as acc) =
            if check key value then
                ( count + 1
                , Tuple.second (insertHelp key value root)
                )

            else
                acc
    in
    untuple (foldl step ( 0, nil ) avl)


{-| -}
partition : (comparable -> value -> Bool) -> AVL comparable value -> ( AVL comparable value, AVL comparable value )
partition check avl =
    let
        step : comparable -> value -> ( ( Int, Node comparable value ), ( Int, Node comparable value ) ) -> ( ( Int, Node comparable value ), ( Int, Node comparable value ) )
        step key value ( ( leftCount, leftRoot ) as left, ( rightCount, rightRoot ) as right ) =
            if check key value then
                ( ( leftCount + 1
                  , Tuple.second (insertHelp key value leftRoot)
                  )
                , right
                )

            else
                ( left
                , ( rightCount + 1
                  , Tuple.second (insertHelp key value rightRoot)
                  )
                )
    in
    Tuple.mapBoth untuple untuple (foldl step ( ( 0, nil ), ( 0, nil ) ) avl)


{-| -}
foldl : (key -> value -> acc -> acc) -> acc -> AVL key value -> acc
foldl fn acc (Internal.AVL _ root) =
    foldlHelp fn acc root


foldlHelp : (key -> value -> acc -> acc) -> acc -> Node key value -> acc
foldlHelp fn acc node =
    case node of
        RBEmpty_elm_builtin ->
            acc

        RBNode_elm_builtin _ k v l r ->
            foldlHelp fn (fn k v (foldlHelp fn acc l)) r


{-| -}
foldr : (key -> value -> acc -> acc) -> acc -> AVL key value -> acc
foldr fn acc (Internal.AVL _ root) =
    foldrHelp fn acc root


foldrHelp : (key -> value -> acc -> acc) -> acc -> Node key value -> acc
foldrHelp fn acc node =
    case node of
        RBEmpty_elm_builtin ->
            acc

        RBNode_elm_builtin _ k v l r ->
            foldrHelp fn (fn k v (foldrHelp fn acc r)) l



-- C O M B I N E


{-| -}
union : AVL comparable value -> AVL comparable value -> AVL comparable value
union left right =
    foldl insert right left


{-| -}
intersect : AVL comparable value -> AVL comparable value -> AVL comparable value
intersect left right =
    let
        step : comparable -> value -> Bool
        step key _ =
            member key right
    in
    filter step left


{-| -}
diff : AVL comparable value -> AVL comparable value -> AVL comparable value
diff left right =
    let
        step : comparable -> value -> AVL comparable value -> AVL comparable value
        step key _ acc =
            remove key acc
    in
    foldl step left right


{-| -}
merge :
    (comparable -> left -> acc -> acc)
    -> (comparable -> left -> right -> acc -> acc)
    -> (comparable -> right -> acc -> acc)
    -> AVL comparable left
    -> AVL comparable right
    -> acc
    -> acc
merge onLeft onBoth onRight left right acc =
    let
        stepAll : comparable -> right -> ( List ( comparable, left ), acc ) -> ( List ( comparable, left ), acc )
        stepAll rk rv ( list, semiacc ) =
            case list of
                [] ->
                    ( []
                    , onRight rk rv semiacc
                    )

                ( lk, lv ) :: rest ->
                    case compare lk rk of
                        LT ->
                            stepAll rk rv ( rest, onLeft lk lv semiacc )

                        GT ->
                            ( list
                            , onRight rk rv semiacc
                            )

                        EQ ->
                            ( rest
                            , onBoth lk lv rv semiacc
                            )

        stepOverLeft : ( comparable, left ) -> acc -> acc
        stepOverLeft ( lk, lv ) semiacc =
            onLeft lk lv semiacc

        ( leftovers, accAll ) =
            foldl stepAll ( toList left, acc ) right
    in
    List.foldl stepOverLeft accAll leftovers
