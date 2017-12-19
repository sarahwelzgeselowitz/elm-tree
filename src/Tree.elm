module Tree exposing (build, traverseBreadthFirst, traverseDepthFirst, view)

import Html exposing (Html, div, li, text, ul)



type Tree comparable data
    = Tree comparable (Data data) (List (Tree comparable data))


type Data data
    = Data data


build :
    (data -> comparable)
    -> (data -> Maybe comparable)
    -> List data
    -> Maybe (Tree comparable data)
build id parentId items =
    case List.partition (isRoot parentId) items of
        ( [ root ], rest ) ->
            Just (attachChildren id parentId rest root)

        _ ->
            Nothing


traverseDepthFirst : (data -> data -> Order) -> Tree comparable data -> List data
traverseDepthFirst sort tree =
    data tree
        :: List.concatMap (traverseDepthFirst sort)
            (children tree |> List.sortWith (compareTrees sort))


traverseBreadthFirst : (data -> data -> Order) -> Tree comparable data -> List data
traverseBreadthFirst sort tree =
    traverseBreadthFirstHelper sort [ tree ]


traverseBreadthFirstHelper : (data -> data -> Order) -> List (Tree comparable data) -> List data
traverseBreadthFirstHelper sort treeList =
    case treeList of
        [] ->
            []

        trees ->
            List.concat
                [ trees |> List.sortWith (compareTrees sort) |> List.map data
                , traverseBreadthFirstHelper sort (List.concatMap children trees)
                ]


compareTrees : (data -> data -> Order) -> Tree comparable data -> Tree comparable data -> Order
compareTrees sort t1 t2 =
    sort (data t1) (data t2)


attachChildren :
    (data -> comparable)
    -> (data -> Maybe comparable)
    -> List data
    -> data
    -> Tree comparable data
attachChildren id parentId candidates item =
    let
        ( children, rest ) =
            List.partition (isChild id parentId item) candidates
    in
    Tree (id item) (Data item) <| List.map (attachChildren id parentId rest) children


isChild :
    (item -> comparable)
    -> (item -> Maybe comparable)
    -> item
    -> item
    -> Bool
isChild id parentId item candidate =
    case parentId candidate of
        Just someId ->
            someId == id item

        Nothing ->
            False


isRoot : (item -> Maybe comparable) -> item -> Bool
isRoot parentId item =
    case parentId item of
        Nothing ->
            True

        _ ->
            False


data : Tree comparable data -> data
data (Tree _ (Data data) _) =
    data


children : Tree comparable data -> List (Tree comparable data)
children (Tree _ _ children) =
    children


view : (data -> Html msg)-> (data -> data -> Order) -> Tree comparable data -> Html msg
view render sort root =
    ul [] [ nodeView render sort root ]


nodeView : (data -> Html msg) -> (data -> data -> Order) ->  Tree comparable data -> Html msg
nodeView render sort tree =
    li []
        [ data tree |> render
        , ul [] (children tree |> List.sortWith (compareTrees sort) |> List.map (view render sort))
        ]
