module Spec.Scenario.State.NavigationHelpers exposing
  ( navigatedSubject
  , handleUrlRequest
  )

import Spec.Setup.Internal exposing (Subject, ProgramView(..))
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Html
import Url


handleUrlRequest : model -> UrlRequest -> ( model, Cmd msg )
handleUrlRequest model request =
  case request of
    Internal url ->
      ( model
      , Browser.Navigation.load <| Url.toString url
      )
    External url ->
      ( model
      , Browser.Navigation.load url
      )


navigatedSubject : String -> Subject model msg -> Subject model msg
navigatedSubject url subject =
  { subject | view = navigatedView url, update = navigatedUpdate }


navigatedView : String -> ProgramView model msg
navigatedView location =
  Element <| \_ ->
    Html.text <| "[Navigated to a page outside the control of the Elm program: " ++ location ++ "]"


navigatedUpdate : msg -> model -> (model, Cmd msg)
navigatedUpdate =
  \_ model ->
    ( model, Cmd.none )
