module Backend exposing (app, init, update, updateFromFrontend)

import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time
import Lamdera exposing (ClientId, SessionId)
import Time
import Types exposing (..)


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    ( { countToFrontendState = Nothing }
    , Command.none
    )


{-| The timer only runs while there is a count in progress. 30ms is the same
interval the real app steps its backend export on.
-}
subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    case model.countToFrontendState of
        Just _ ->
            Effect.Time.every (Duration.milliseconds 30) (\_ -> CountToFrontendStep)

        Nothing ->
            Subscription.none


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
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
                    , Effect.Lamdera.sendToFrontend
                        (Effect.Lamdera.clientIdFromString countState.clientId)
                        (CountToFrontend countState.count)
                    )

                Nothing ->
                    ( model, Command.none )


updateFromFrontend : Effect.Lamdera.SessionId -> Effect.Lamdera.ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        CountToBackendRequest ->
            ( { model | countToFrontendState = Just { count = 0, clientId = Effect.Lamdera.clientIdToString clientId, busyWork = 0 } }
            , Command.none
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
