module ClickSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim as Claim
import Spec.Http
import Spec.Http.Route exposing (..)
import Runner
import Main as App


clickSpec : Spec App.Model App.Msg
clickSpec =
  Spec.describe "an html program"
  [ tagged [ "fun" ] <|
    scenario "a click event" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "my-button" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (Markup.hasText "You clicked the button 3 time(s)")
      )
    )
  , tagged [ "fun" ] <|
    scenario "click to make a request" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "request-button" ]
        , Event.click
        ]
      |> it "makes the request" (
        Spec.Http.observeRequests (get "http://fake-api.com/stuff")
          |> expect (Claim.isListWhere
            [ Spec.Http.hasHeader ("X-Awesome-Header", "some-awesome-value")
            ]
          )
      )
    )
  ]


main =
  Runner.program
    [ clickSpec
    ]