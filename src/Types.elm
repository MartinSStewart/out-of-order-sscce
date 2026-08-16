module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Lamdera exposing (ClientId)
import Url exposing (Url)


type alias FrontendModel =
    { received : String
    }


type alias BackendModel =
    { countToFrontendState : Maybe CountToFrontendState
    }


{-| The next count the frontend is waiting on, plus the client it is going to.
-}
type alias CountToFrontendState =
    { count : Int
    , clientId : ClientId
    , busyWork : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | PressedCountToBackend
    | NoOpFrontendMsg


type ToBackend
    = CountToBackendRequest


type BackendMsg
    = CountToFrontendStep


type ToFrontend
    = CountToFrontend Int
