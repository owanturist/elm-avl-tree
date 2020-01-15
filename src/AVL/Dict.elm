module AVL.Dict exposing
    ( Dict
    , Comparator
    , empty, emptyWith, singleton, singletonWith, fromList, fromListWith
    , keys, values, toList
    , insert, remove, update, clear
    , isEmpty, size, member, get
    , map, filter, partition, foldl, foldr
    , union, diff, intersect, merge
    )

{-| An AVL Tree based dictionary.

A dictionary mapping unique keys to values.
The keys can be any type.
This includes both custom and comparable types such as Int, Float, Time, Char, String, and tuples or lists of comparable types.

Insert, remove, get and member operations all take `O(log n)` time.
Size takes constant `O(1)` time.


# Dictionary

@docs Dict


# Construction

@docs Comparator
@docs empty, emptyWith, singleton, singletonWith, fromList, fromListWith


# Deconstruction

@docs keys, values, toList


# Manipulation

@docs insert, remove, update, clear


# Query

@docs isEmpty, size, member, get


# Transform

@docs map, filter, partition, foldl, foldr


# Combine

@docs union, diff, intersect, merge

-}

import Internal


{-| A dictionary of keys and values.
So a `Dict String User` is a dictionary
that lets you look up a `String` (such as user names)
and find the associated `User`.

    import AVL.Dict as Dict exposing (Dict)

    users : Dict String User
    users =
        Dict.fromList
            [ ( "Alice", User "Alice" 28 1.65 )
            , ( "Bob", User "Bob" 19 1.82 )
            , ( "Chuck", User "Chuck" 33 1.75 )
            ]

    type alias User =
        { name : String
        , age : Int
        , height : Float
        }

-}
type alias Dict key value =
    Internal.AVLDict key value


{-| A comparator is a function which compares two keys.
So a `Dict ID User` is a dictionary
that lets you look up a `ID` (such as user ids)
and find the associated `User`.

    import AVL.Dict as Dict exposing (Comparator, Dict)

    type ID
        = ID Int

    idComparator : Comparator ID
    idComparator (ID x) (ID y) =
        compare x y

    users : Dict ID User
    users =
        Dict.fromListWith idComparator
            [ ( ID 0, User (ID 0) "Alice" 28 1.65 )
            , ( ID 1, User (ID 1) "Bob" 19 1.82 )
            , ( ID 2, User (ID 2) "Chuck" 33 1.75 )
            ]

    alice : Maybe User
    alice =
        Dict.get (ID 0) users

    type alias User =
        { id : ID
        , name : String
        , age : Int
        , height : Float
        }

-}
type alias Comparator key =
    key -> key -> Order



-- U T I L S


untuple : Comparator key -> ( Int, Internal.Node key value ) -> Dict key value
untuple comparator ( count, root ) =
    Internal.AVLDict comparator count root



-- C O N S T R U C T I O N


{-| Create an empty dictionary with custom key comparator.
-}
emptyWith : Comparator key -> Dict key value
emptyWith comparator =
    Internal.AVLDict comparator 0 Internal.nil


{-| Create an empty dictionary.
-}
empty : Dict comparable value
empty =
    emptyWith compare


{-| Create a dictionary with one key-value pair with custom key comparator.
-}
singletonWith : Comparator key -> key -> value -> Dict key value
singletonWith comparator key value =
    Internal.AVLDict comparator 1 (Internal.singleton key value)


{-| Create a dictionary with one key-value pair.
-}
singleton : comparable -> value -> Dict comparable value
singleton =
    singletonWith compare


{-| Convert an association list into a dictionary with custom key comparator.
-}
fromListWith : Comparator key -> List ( key, value ) -> Dict key value
fromListWith comparator list =
    untuple comparator (List.foldl (Internal.fromList comparator) ( 0, Internal.nil ) list)


{-| Convert an association list into a dictionary.
-}
fromList : List ( comparable, value ) -> Dict comparable value
fromList =
    fromListWith compare



-- D E C O N S T R U C T I O N


{-| Get all of the keys in a dictionary, sorted from lowest to highest.

    keys (fromList [ ( 1, "Bob" ), ( 0, "Alice" ) ]) == [ 0, 1 ]

-}
keys : Dict key value -> List key
keys avl =
    foldr keysStep [] avl


keysStep : key -> value -> List key -> List key
keysStep key _ acc =
    key :: acc


{-| Get all of the values in a dictionary, in the order of their keys.

    values (fromList [ ( 1, "Bob" ), ( 0, "Alice" ) ]) == [ "Alice", "Bob" ]

-}
values : Dict key value -> List value
values avl =
    foldr valuesStep [] avl


valuesStep : key -> value -> List value -> List value
valuesStep _ value acc =
    value :: acc


{-| Convert a dictionary into an association list of key-value pairs, sorted by keys.

    toList (fromList [ ( 1, "Bob" ), ( 0, "Alice" ) ]) == [ ( 0, "Alice" ), ( 1, "Bob" ) ]

-}
toList : Dict key value -> List ( key, value )
toList avl =
    foldr toListStep [] avl


toListStep : key -> value -> List ( key, value ) -> List ( key, value )
toListStep key value acc =
    ( key, value ) :: acc



-- M A N I P U L A T I O N


{-| Insert a key-value pair into a dictionary.
Replaces value when there is a collision.
-}
insert : key -> value -> Dict key value -> Dict key value
insert key value (Internal.AVLDict comparator count root) =
    let
        ( added, nextRoot ) =
            Internal.insert comparator key value root
    in
    if added then
        Internal.AVLDict comparator (count + 1) nextRoot

    else
        Internal.AVLDict comparator count nextRoot


{-| Remove a key-value pair from a dictionary.
If the key is not found, no changes are made.
-}
remove : key -> Dict key value -> Dict key value
remove key ((Internal.AVLDict comparator count root) as avl) =
    case Internal.remove comparator key root of
        Nothing ->
            avl

        Just nextRoot ->
            Internal.AVLDict comparator (count - 1) nextRoot


{-| Update the value of a dictionary for a specific key with a given function.
-}
update : key -> (Maybe value -> Maybe value) -> Dict key value -> Dict key value
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


{-| Remove all entries from a dictionary.
Useful when you need to create new empty dictionary using same comparator.
-}
clear : Dict key value -> Dict key value
clear (Internal.AVLDict comparator _ _) =
    emptyWith comparator



-- Q U E R Y


{-| Determine if a dictionary is empty.
-}
isEmpty : Dict key value -> Bool
isEmpty avl =
    size avl == 0


{-| Determine the number of key-value pairs in the dictionary.
It takes constant time to request the size.
-}
size : Dict key value -> Int
size (Internal.AVLDict _ count _) =
    count


{-| Determine if a key is in a dictionary.
-}
member : key -> Dict key value -> Bool
member key avl =
    get key avl /= Nothing


{-| Get the value associated with a key. If the key is not found, return Nothing.
This is useful when you are not sure if a key will be in the dictionary.

    animals =
        fromList [ ( "Tom", Cat ), ( "Jerry", Mouse ) ]

    get "Tom" animals == Just Cat
    get "Jerry" animals == Just Mouse
    get "Spike" animals == Nothing

-}
get : key -> Dict key value -> Maybe value
get key (Internal.AVLDict comparator _ root) =
    Internal.get comparator key root



-- T R A N S F O R M


{-| Apply a function to all values in a dictionary.
-}
map : (key -> a -> b) -> Dict key a -> Dict key b
map fn (Internal.AVLDict comparator count root) =
    Internal.AVLDict comparator count (Internal.map fn root)


{-| Keep only the key-value pairs that pass the given test.
-}
filter : (key -> value -> Bool) -> Dict key value -> Dict key value
filter check (Internal.AVLDict comparator _ root) =
    untuple comparator (Internal.foldl (Internal.filter comparator check) ( 0, Internal.nil ) root)


{-| Partition a dictionary according to some test.
The first dictionary contains all key-value pairs which passed the test,
and the second contains the pairs that did not.
-}
partition : (key -> value -> Bool) -> Dict key value -> ( Dict key value, Dict key value )
partition check (Internal.AVLDict comparator _ root) =
    Tuple.mapBoth
        (untuple comparator)
        (untuple comparator)
        (Internal.foldl (Internal.partition comparator check) ( ( 0, Internal.nil ), ( 0, Internal.nil ) ) root)


{-| Fold over the key-value pairs in a dictionary from lowest key to highest key.
-}
foldl : (key -> value -> acc -> acc) -> acc -> Dict key value -> acc
foldl fn acc (Internal.AVLDict _ _ root) =
    Internal.foldl fn acc root


{-| Fold over the key-value pairs in a dictionary from highest key to lowest key.
-}
foldr : (key -> value -> acc -> acc) -> acc -> Dict key value -> acc
foldr fn acc (Internal.AVLDict _ _ root) =
    Internal.foldr fn acc root



-- C O M B I N E


{-| Combine two dictionaries.
If there is a collision, preference is given to the left dictionary.
-}
union : Dict key value -> Dict key value -> Dict key value
union left right =
    foldl insert right left


{-| Keep a key-value pair when its key appears in the right dictionary.
Preference is given to values in the left dictionary.
-}
intersect : Dict key value -> Dict key value -> Dict key value
intersect left right =
    let
        step : key -> value -> Bool
        step key _ =
            member key right
    in
    filter step left


{-| Keep a key-value pair when its key does not appear in the right dictionary.
-}
diff : Dict key value -> Dict key value -> Dict key value
diff left right =
    foldl diffStep left right


diffStep : key -> value -> Dict key value -> Dict key value
diffStep key _ acc =
    remove key acc


{-| The most general way of combining two dictionaries.
You provide three accumulators for when a given key appears:

1.  Only in the left dictionary.
2.  In both dictionaries.
3.  Only in the right dictionary.

You then traverse all the keys from lowest to highest, building up whatever you want.

-}
merge :
    (key -> left -> acc -> acc)
    -> (key -> left -> right -> acc -> acc)
    -> (key -> right -> acc -> acc)
    -> Dict key left
    -> Dict key right
    -> acc
    -> acc
merge onLeft onBoth onRight (Internal.AVLDict comparator _ left) (Internal.AVLDict _ _ right) acc =
    Internal.merge comparator onLeft onBoth onRight left right acc
