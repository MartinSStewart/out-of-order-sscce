module Frontend exposing (app)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Lamdera
import Types exposing (..)
import Url


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init _ key =
    ( { key = key, received = "" }
    , Cmd.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                External url ->
                    ( model, Nav.load url )

        UrlChanged _ ->
            ( model, Cmd.none )

        PressedCountToBackend ->
            ( { model | received = "" }
            , Lamdera.sendToBackend CountToBackendRequest
            )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


{-| Every count that arrives is appended, so the whole sequence can be read
afterwards rather than only whichever one happened to arrive last.
-}
updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        CountToFrontend count ->
            ( { model | received = model.received ++ " " ++ String.fromInt count }
            , Cmd.none
            )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Counting to 200"
    , body =
        [ Html.div
            [ Html.Attributes.style "font-family" "sans-serif"
            , Html.Attributes.style "padding" "16px"
            ]
            [ Html.button
                [ Html.Events.onClick PressedCountToBackend ]
                [ Html.text "Count to 200" ]
            , Html.p
                [ Html.Attributes.style "font-family" "monospace"
                , Html.Attributes.style "line-height" "1.6"
                , Html.Attributes.style "word-break" "break-all"
                ]
                [ Html.text model.received ]
            ]
        ]
    }
