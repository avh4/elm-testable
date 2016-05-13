module FakeSet exposing (Set, member, empty, singleton, union, remove, insert)


type Set a
    = Set (List a)


member : a -> Set a -> Bool
member expected (Set set) =
    List.any ((==) expected) set


empty : Set a
empty =
    Set []


singleton : a -> Set a
singleton a =
    Set [ a ]


union : Set a -> Set a -> Set a
union (Set left) (Set right) =
    Set (left ++ right)


remove : a -> Set a -> Set a
remove x (Set set) =
    Set (List.filter ((/=) x) set)


insert : a -> Set a -> Set a
insert a (Set set) =
    Set (a :: set)
