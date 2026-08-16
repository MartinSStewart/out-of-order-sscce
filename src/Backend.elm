module Backend exposing (app, init, update, updateFromFrontend)

import Lamdera exposing (ClientId, SessionId)
import Time
import Types exposing (..)


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( BackendModel, Cmd BackendMsg )
init =
    ( { countToFrontendState = Nothing }
    , Cmd.none
    )


{-| The timer only runs while there is a count in progress. 30ms is the same
interval the real app steps its backend export on.
-}
subscriptions : BackendModel -> Sub BackendMsg
subscriptions model =
    case model.countToFrontendState of
        Just _ ->
            Time.every 30 (\_ -> CountToFrontendStep)

        Nothing ->
            Sub.none


update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
update msg model =
    case msg of
        CountToFrontendStep ->
            case model.countToFrontendState of
                Just countState ->
                    ( if countState.count >= 200 then
                        { model | countToFrontendState = Nothing }

                      else
                        { model
                            | countToFrontendState =
                                Just
                                    { countState
                                        | count = countState.count + 1
                                        , busyWork =
                                            if modBy 3 countState.count == 0 then
                                                slowlyCountTo 24000000 countState.busyWork

                                            else
                                                0
                                    }
                        }
                    , Lamdera.sendToFrontend countState.clientId (CountToFrontend countState.count)
                    )

                Nothing ->
                    ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        CountToBackendRequest ->
            ( { model | countToFrontendState = Just { count = 0, clientId = clientId, busyWork = 0 } }
            , Cmd.none
            )


{-| Burns CPU so a CountToFrontendStep update takes longer than the 30ms between
ticks. 14 million iterations measured at around 50ms.

The total it returns is meaningless. It gets kept in the backend model so that
neither the Elm optimizer nor the JIT can decide the loop isn't worth running.

Drop this to `slowlyCountTo 0` to see the same count without the overrun.

-}
slowlyCountTo : Int -> Int -> Int
slowlyCountTo iterations total =
    if iterations <= 0 then
        total

    else
        slowlyCountTo (iterations - 1) (total + modBy 7 iterations)
