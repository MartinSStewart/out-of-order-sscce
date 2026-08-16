# Counting to 200 from the backend

A Lamdera app that does one thing: you press a button, and the backend sends the
numbers 0 to 200 to that client, one per `Time.every` tick.

Each number arrives in its own `sendToFrontend`, from its own `Backend.update`
call. The frontend appends every number it receives to a string and displays it,
so the whole sequence can be read afterwards rather than only whichever number
happened to arrive last.

## Running it

```
lamdera live
```

Then open http://localhost:8000 and press the button. It takes about ten
seconds.

## What to look for

The displayed sequence should read `0 1 2 3 … 199 200`: in order, no gaps, no
repeats, and each number exactly once.

## The part that makes this interesting

The timer is 30ms (`Backend.subscriptions`), but each `CountToFrontendStep`
update deliberately takes longer than that. `Backend.slowlyCountTo` burns about
50ms of CPU per step, measured with `lamdera make --optimize` at roughly 3.6ms
per million iterations, so the tick that drives the count fires again before the
previous step has finished.

The busy work's result is meaningless. It is kept in the backend model
(`CountToFrontendState.busyWork`) rather than discarded, so that neither the Elm
optimizer nor the JIT can decide the loop isn't worth running.

To see the same count without the overrun, change the `14000000` in
`Backend.update` to `0`.

## Where everything is

| | |
| --- | --- |
| `src/Types.elm` | `CountToFrontendState`, the three message types |
| `src/Backend.elm` | the 30ms subscription, the step, the busy work |
| `src/Frontend.elm` | the button, and appending each number as it arrives |

Nothing else is going on in the app — no other subscriptions, no other messages,
no ports.
