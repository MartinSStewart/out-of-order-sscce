module Frontend exposing (app)

import Browser exposing (UrlRequest(..))
import Effect.Browser.Navigation as Nav
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Subscription as Subscription
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Lamdera
import Types exposing (..)
import Url


app =
    Effect.Lamdera.frontend
        Lamdera.sendToBackend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Subscription.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
init _ key =
    ( { received = "" }
    , Command.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            ( model, Command.none )

        UrlChanged _ ->
            ( model, Command.none )

        PressedCountToBackend ->
            ( { model | received = "" }
            , Effect.Lamdera.sendToBackend CountToBackendRequest
            )

        NoOpFrontendMsg ->
            ( model, Command.none )


{-| Every count that arrives is appended, so the whole sequence can be read
afterwards rather than only whichever one happened to arrive last.
-}
updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        CountToFrontend count ->
            ( { model | received = model.received ++ " " ++ String.fromInt count }
            , Command.none
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
