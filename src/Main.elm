module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import RemoteData exposing (RemoteData)


type alias Model =
    { input : String
    , output : RemoteData.WebData String
    }


type Msg
    = GotInput String
    | Format
    | FormatResponse (RemoteData.WebData String)


initialModel : Model
initialModel =
    { input = "module Main exposing (..)\n\n"
    , output = RemoteData.NotAsked
    }


main : Program () Model Msg
main =
    Browser.document
        { init = \_ -> ( initialModel, Cmd.none )
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotInput newInput ->
            ( { model | input = newInput, output = RemoteData.NotAsked }
            , Cmd.none
            )

        Format ->
            if RemoteData.isNotAsked model.output || RemoteData.isFailure model.output then
                ( { model | output = RemoteData.Loading }
                , format model.input
                )

            else
                ( model, Cmd.none )

        FormatResponse newOutput ->
            ( { model | output = newOutput, input = newOutput |> RemoteData.toMaybe |> Maybe.withDefault model.input }
            , Cmd.none
            )


format : String -> Cmd Msg
format code =
    Http.post
        { url = "http://localhost:8080/"
        , body = Http.stringBody "text/plain" code
        , expect = Http.expectString (RemoteData.fromResult >> FormatResponse)
        }


view : Model -> Browser.Document Msg
view { input, output } =
    { title = "elm-format"
    , body =
        [ Html.div [ Attr.style "padding" ".5rem 1rem" ]
            [ Html.h1 [] [ Html.text "elm-format" ]
            , Html.div [ Attr.style "display" "flex" ]
                [ Html.textarea
                    [ Events.onInput GotInput
                    , Events.onBlur Format
                    , Attr.style "width" "100%"
                    , Attr.style "font-family" "monospace"
                    , Attr.rows 20
                    , Attr.value input
                    ]
                    []
                ]
            , Html.div []
                [ Html.button
                    [ Events.onClick Format
                    , Attr.disabled (RemoteData.isLoading output)
                    ]
                    [ Html.text "Format!" ]
                , Html.span
                    [ Attr.style "margin-left" "1rem" ]
                    [ viewStatus output ]
                ]
            ]
        ]
    }


viewStatus : RemoteData.WebData String -> Html Msg
viewStatus data =
    case data of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.span
                [ Attr.style "color" "#666" ]
                [ Html.text "Formatting..." ]

        RemoteData.Failure (Http.BadUrl url) ->
            viewError ("Bad URL: " ++ url)

        RemoteData.Failure Http.Timeout ->
            viewError "It took too long to get a response."

        RemoteData.Failure Http.NetworkError ->
            viewError "Please check your connection."

        RemoteData.Failure (Http.BadStatus status) ->
            viewError ("Bad Status: " ++ String.fromInt status)

        RemoteData.Failure (Http.BadBody debug) ->
            viewError ("Bad Body: " ++ debug)

        RemoteData.Success code ->
            Html.span
                [ Attr.style "color" "#090" ]
                [ Html.text "Formatted!" ]


viewError : String -> Html msg
viewError message =
    Html.span
        [ Attr.style "color" "#f00" ]
        [ Html.text ("Error! " ++ message) ]


viewOutput : RemoteData.WebData String -> Html Msg
viewOutput data =
    case data of
        RemoteData.Success code ->
            Html.text code

        _ ->
            Html.text ""
