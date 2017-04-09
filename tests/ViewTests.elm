module ViewTests exposing (all)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


htmlProgram : TestContext (List ( String, String )) ( String, String )
htmlProgram =
    { model = []
    , update = \msg model -> msg :: model
    , view =
        \model ->
            Html.section []
                [ Html.h1 [] [ Html.text "Title!" ]
                , model
                    |> List.map (\( tag, text ) -> Html.node tag [] [ Html.text text ])
                    |> Html.div []
                ]
    }
        |> Html.beginnerProgram
        |> TestContext.start


all : Test
all =
    describe "View"
        [ test "verifying an initial view" <|
            \() ->
                htmlProgram
                    |> TestContext.expectView
                        (Query.find [ Selector.tag "h1" ]
                            >> Query.has [ Selector.text "Title!" ]
                        )
        ]
