module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import RemoteData exposing (RemoteData)


type alias Model =
    { code : String
    , format : RemoteData FormatError ()
    }


type Msg
    = GotCode String
    | Format
    | FormatResponse (RemoteData FormatError String)
    | ValidateResponse (RemoteData FormatError String)


type FormatError
    = HttpBadUrl String
    | HttpTimeout
    | HttpNetworkError
    | HttpBadStatus Int String -- 400 < status < 500
    | ServerError Int String -- status >= 500
    | SyntaxProblem String -- status == 400


initialModel : Model
initialModel =
    { code = "module Main exposing (..)\n\n"
    , format = RemoteData.NotAsked
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
        GotCode newCode ->
            ( { model
                | code = newCode
                , format = RemoteData.NotAsked
              }
            , validate newCode
            )

        Format ->
            if RemoteData.isNotAsked model.format || RemoteData.isFailure model.format then
                ( { model
                    | format = RemoteData.Loading
                  }
                , format model.code
                )

            else
                ( model, Cmd.none )

        FormatResponse newFormat ->
            ( { model
                | code = newFormat |> RemoteData.toMaybe |> Maybe.withDefault model.code
                , format = RemoteData.map (\_ -> ()) newFormat
              }
            , Cmd.none
            )

        ValidateResponse newValidate ->
            ( { model
                | format = RemoteData.unwrap RemoteData.NotAsked (\_ -> RemoteData.succeed ()) newValidate
              }
            , Cmd.none
            )


validate : String -> Cmd Msg
validate code =
    Http.post
        { url = "http://localhost:8080/validate"
        , body = Http.stringBody "text/plain" code
        , expect = Http.expectStringResponse (RemoteData.fromResult >> ValidateResponse) formatResponse
        }


format : String -> Cmd Msg
format code =
    Http.post
        { url = "http://localhost:8080/"
        , body = Http.stringBody "text/plain" code
        , expect = Http.expectStringResponse (RemoteData.fromResult >> FormatResponse) formatResponse
        }


formatResponse : Http.Response String -> Result FormatError String
formatResponse response =
    case response of
        Http.BadUrl_ url ->
            Err (HttpBadUrl url)

        Http.Timeout_ ->
            Err HttpTimeout

        Http.NetworkError_ ->
            Err HttpNetworkError

        Http.BadStatus_ metadata body ->
            if metadata.statusCode == 400 then
                Err (SyntaxProblem body)

            else if metadata.statusCode >= 500 then
                Err (ServerError metadata.statusCode body)

            else
                Err (HttpBadStatus metadata.statusCode body)

        Http.GoodStatus_ _ body ->
            Ok body


view : Model -> Browser.Document Msg
view model =
    { title = "elm-format"
    , body =
        [ Html.div [ Attr.style "padding" ".5rem 1rem" ]
            [ Html.h1 [] [ Html.text "elm-format" ]
            , Html.div [ Attr.style "display" "flex" ]
                [ Html.textarea
                    [ Events.onInput GotCode
                    , Events.onBlur Format
                    , Attr.disabled (RemoteData.isLoading model.format)
                    , Attr.style "width" "100%"
                    , Attr.style "font-family" "monospace"
                    , Attr.rows 20
                    , Attr.value model.code
                    ]
                    []
                ]
            , Html.div
                [ Attr.style "margin-top" ".5rem"
                ]
                [ Html.button
                    [ Events.onClick Format
                    , Attr.disabled (RemoteData.isLoading model.format || RemoteData.isSuccess model.format)
                    ]
                    [ Html.text "Format!" ]
                , Html.span
                    [ Attr.style "margin-left" "1rem" ]
                    [ viewFormatStatus model.format
                    ]
                ]
            , viewSyntaxError model.format
            ]
        ]
    }


viewFormatStatus : RemoteData FormatError () -> Html msg
viewFormatStatus data =
    case data of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.span
                [ Attr.style "color" "#666" ]
                [ Html.text "Formatting..." ]

        RemoteData.Failure (HttpBadUrl url) ->
            viewError ("Bad URL: " ++ url)

        RemoteData.Failure HttpTimeout ->
            viewError "It took too long to get a response."

        RemoteData.Failure HttpNetworkError ->
            viewError "Please check your connection."

        RemoteData.Failure (HttpBadStatus status message) ->
            viewError ("Bad Status (" ++ String.fromInt status ++ "): " ++ message)

        RemoteData.Failure (ServerError status message) ->
            viewError ("Server Error (" ++ String.fromInt status ++ "): " ++ message)

        RemoteData.Failure (SyntaxProblem _) ->
            viewError "Syntax Problem..."

        RemoteData.Success () ->
            Html.span
                [ Attr.style "color" "#090" ]
                [ Html.text "Formatted!" ]


viewSyntaxError : RemoteData FormatError a -> Html msg
viewSyntaxError data =
    case data of
        RemoteData.Failure (SyntaxProblem message) ->
            Html.div
                [ Attr.style "font-family" "monospace"
                , Attr.style "white-space" "pre-wrap"
                , Attr.style "border" "1px solid #999"
                , Attr.style "margin-top" "1rem"
                , Attr.style "padding" "2px"
                , Attr.style "overflow-wrap" "break-word"
                ]
                [ Html.text message ]

        _ ->
            Html.text ""


viewError : String -> Html msg
viewError message =
    Html.span
        [ Attr.style "color" "#f00" ]
        [ Html.text ("Error! " ++ message) ]
