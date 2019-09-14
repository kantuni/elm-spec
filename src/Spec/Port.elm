module Spec.Port exposing
  ( observe
  , send
  , expect
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Step as Step
import Spec.Observation as Observation exposing (Observation)
import Spec.Observer as Observer exposing (Observer)
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


sendSubscription : String -> Encode.Value -> Message
sendSubscription name value =
  { home = "_port"
  , name = "send"
  , body = Encode.object [ ("sub", Encode.string name), ("value", value) ]
  }


observePortCommand : String -> Message
observePortCommand name =
  { home = "_port"
  , name = "receive"
  , body = Encode.object [ ("cmd", Encode.string name) ]
  }


observe : String -> Subject model msg -> Subject model msg
observe portName =
  observePortCommand portName
    |> Subject.configure


send : String -> Encode.Value -> Step.Context model -> Step.Command msg
send name value _ =
  Step.sendMessage <| sendSubscription name value


expect : String -> Json.Decoder a -> Observer (List a) -> Observation model
expect name decoder observer =
  Observation.selectEffects
    |> Observation.mapSelection (\messages ->
      List.filter (Message.is "_port" "received") messages
        |> List.filterMap (Message.decode decoder)
    )
    |> Observation.expect observer
