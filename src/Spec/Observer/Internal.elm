module Spec.Observer.Internal exposing
  ( Observer
  , for
  , observeEffects
  , inquire
  , expect
  , observeClaim
  )

import Spec.Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observer.Expectation as Expectation exposing (Expectation)


type Observer model a =
  Observer
    (Claim a -> Expectation model)


for : (Claim a -> Expectation model) -> Observer model a
for =
  Observer


observeClaim : (Claim a -> Claim b) -> Observer model b -> Observer model a
observeClaim generator (Observer observer) =
  Observer <| \claim ->
    observer <| generator claim


expect : Claim a -> Observer model a -> Expectation model
expect claim (Observer observer) =
  observer claim


observeEffects : (List Message -> a) -> Observer model a
observeEffects mapper =
  Observer <| \claim ->
    Expectation.Expectation <| \context ->
      mapper context.effects
        |> claim
        |> Expectation.Complete


inquire : Message -> (Message -> a) -> Observer model a
inquire message mapper =
  Observer <| \claim ->
    Expectation.Expectation <| \context ->
      Expectation.Inquire message <|
        \response ->
          mapper response
            |> claim
            |> Expectation.Complete