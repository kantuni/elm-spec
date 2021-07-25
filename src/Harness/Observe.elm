module Harness.Observe exposing 
  ( Model, defaultModel
  , Msg(..)
  , Actions
  , init
  , update
  , ExposedExpectationRepository
  )

import Spec.Claim as Claim exposing (Verdict)
import Spec.Step.Context as Context exposing (Context)
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Observer.Internal exposing (Judgment(..))
import Harness.Types exposing (..)
import Spec.Report as Report
import Json.Decode as Json
import Json.Encode as Encode


type alias Model model =
  { programModel: model
  , effects: List Message
  , inquiryHandler: Maybe (Message -> Judgment model)
  }

defaultModel : model -> List Message -> Model model
defaultModel programModel effects =
  { programModel = programModel
  , effects = effects
  , inquiryHandler = Nothing
  }

type Msg =
  ReceivedMessage Message

type alias Actions msg =
  { send : Message -> Cmd msg
  , finished: Cmd msg
  }


type alias ExposedExpectationRepository model =
  { get: String -> Maybe (ExposedExpectation model)
  }


init : Actions msg -> ExposedExpectationRepository model -> Model model -> Message -> ( Model model, Cmd msg )
init config expectations model message =
  let
    maybeExpectation = Message.decode (Json.field "observer" Json.string) message
      |> Result.toMaybe
      |> Maybe.andThen (\observerName -> expectations.get observerName)
    expected = Message.decode (Json.field "expected" Json.value) message
      |> Result.toMaybe
      |> Maybe.withDefault Encode.null
  in
    case maybeExpectation of
      Just expectation ->
        observe config model (expectation expected)
      Nothing ->
        ( model, Cmd.none )


update : Actions msg -> Msg -> Model model -> ( Model model, Cmd msg )
update config msg model =
  case msg of
    ReceivedMessage message ->
      if Message.belongsTo "_observer" message then
        handleObserveMessage config model message
      else
        ( model, Cmd.none )


observe : Actions msg -> Model model -> Expectation model -> ( Model model, Cmd msg )
observe config model (Expectation expectation) =
  case expectation <| establishContext model.programModel model.effects of
    Complete verdict ->
      ( model
      , sendVerdict config verdict 
      )
    Inquire message handler ->
      ( { model | inquiryHandler = Just handler }
      , config.send <| Message.inquiry message
      )


handleObserveMessage : Actions msg -> Model model -> Message -> ( Model model, Cmd msg )
handleObserveMessage config model message =
  Message.decode Message.inquiryDecoder message
    |> Result.map .message
    |> Result.map (processInquiryMessage config model)
    |> Result.withDefault ( model, Cmd.none )
      -- (abortObservation actions observeModel <| Report.note "Unable to decode inquiry result!")


processInquiryMessage : Actions msg -> Model model -> Message -> ( Model model, Cmd msg )
processInquiryMessage config model message =
  if Message.is "_scenario" "abort" message then
    Debug.todo "Abort while processing inquiry message!"
  else
    ( { model | inquiryHandler = Nothing }
    , handleInquiry message model.inquiryHandler
        |> sendVerdict config
    )


handleInquiry : Message -> Maybe (Message -> Judgment model) -> Verdict
handleInquiry message maybeHandler =
  maybeHandler
    |> Maybe.map (inquiryResult message)
    |> Maybe.withDefault (Claim.Reject <| Report.note "No Inquiry Handler!")


inquiryResult : Message -> (Message -> Judgment model) -> Verdict
inquiryResult message handler =
  case handler message of
    Complete verdict ->
      verdict
    Inquire _ _ ->
      Claim.Reject <| Report.note "Recursive Inquiry not supported!"


establishContext : model -> List Message -> Context model
establishContext programModel effects =
  Context.for programModel
    |> Context.withEffects effects

sendVerdict : Actions msg -> Verdict -> Cmd msg
sendVerdict actions verdict =
  Cmd.batch
    [ Message.observation [] "harness observation" verdict
        |> actions.send
    , actions.finished
    ]