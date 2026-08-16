module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Lamdera
import Url


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , received : String
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Lamdera.ClientId
    , busyWork : Int
    }


type alias BackendModel =
    { countToFrontendState : Maybe CountToFrontendState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | PressedCountToBackend
    | NoOpFrontendMsg


type ToBackend
    = CountToBackendRequest


type BackendMsg
    = CountToFrontendStep


type ToFrontend
    = CountToFrontend Int
