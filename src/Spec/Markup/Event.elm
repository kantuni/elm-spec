module Spec.Markup.Event exposing
  ( click
  , press
  , release
  , mouseMoveIn
  , mouseMoveOut
  , input
  , trigger
  )

import Spec.Step as Step
import Spec.Message as Message
import Json.Encode as Encode
import Json.Decode as Json


click : Step.Context model -> Step.Command msg
click context =
  Step.sendMessage
    { home = "_html"
    , name = "click"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      ]
    }


press : Step.Context model -> Step.Command msg
press =
  trigger "mousedown" <| Encode.object []


release : Step.Context model -> Step.Command msg
release =
  trigger "mouseup" <| Encode.object []


mouseMoveIn : Step.Context model -> Step.Command msg
mouseMoveIn context =
  Step.sendMessage
    { home = "_html"
    , name = "mouseMoveIn"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      ]
    }


mouseMoveOut : Step.Context model -> Step.Command msg
mouseMoveOut context =
  Step.sendMessage
    { home = "_html"
    , name = "mouseMoveOut"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      ]
    }


input : String -> Step.Context model -> Step.Command msg
input text context =
  Step.sendMessage
    { home = "_html"
    , name = "input"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      , ( "text", Encode.string text )
      ]
    }


trigger : String -> Encode.Value -> Step.Context model -> Step.Command msg
trigger name json context =
  Step.sendMessage
    { home = "_html"
    , name = "customEvent"
    , body = Encode.object
      [ ( "selector", Encode.string <| targetSelector context )
      , ( "name", Encode.string name )
      , ( "event", json )
      ]
    }


targetSelector : Step.Context model -> String
targetSelector context =
  context.effects
    |> List.filter (Message.is "_html" "target")
    |> List.head
    |> Maybe.andThen (Message.decode Json.string)
    |> Maybe.withDefault ""
