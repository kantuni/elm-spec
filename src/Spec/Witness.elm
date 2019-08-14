module Spec.Witness exposing
  ( Witness
  , forUpdate
  , spy
  , expect
  , hasReports
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Message as Message exposing (Message)
import Observer exposing (Observer)
import Json.Encode as Encode
import Json.Decode as Json


type Witness msg =
  Witness (Message -> Cmd msg)


type alias Report =
  { name: String
  }


forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> Subject model msg -> Subject model msg
forUpdate updateWithWitness subject =
  { subject | update = \witness -> updateWithWitness <| Witness witness }


spy : String -> Witness msg -> Cmd msg
spy name (Witness witness) =
  witness
    { home = "_witness"
    , name = "spy"
    , body = Encode.object [ ("name", Encode.string name) ]
    }


expect : String -> Observer (List Report) -> Observer (Subject model msg)
expect name reportObserver subject =
  case verdict name reportObserver subject of
    Observer.Accept ->
      Observer.Accept
    Observer.Reject failure ->
      Observer.Reject <|
        "Expected witness\n\t" ++ name ++ failure


verdict : String -> Observer (List Report) -> Observer (Subject model msg)
verdict name reportObserver subject =
  Subject.effects subject
    |> List.filter (Message.is "_witness" "spy")
    |> List.filterMap (Message.decode reportDecoder)
    |> List.filter (\report -> report.name == name)
    |> reportObserver


reportDecoder : Json.Decoder (Report)
reportDecoder =
  Json.map Report
    ( Json.field "name" Json.string )


hasReports : Int -> Observer (List Report)
hasReports times reports =
  if times == List.length reports then
    Observer.Accept
  else
    Observer.Reject <| 
      "\nto have been called " ++ timesString times ++ ", but it was called " ++
      (timesString <| List.length reports) ++ "."


timesString : Int -> String
timesString times =
  if times == 1 then
    (String.fromInt times) ++ " time"
  else
    (String.fromInt times) ++ " times"
