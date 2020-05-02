module Specs.DownloadSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.File
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import File.Download as Download
import Runner
import Specs.Helpers exposing (..)


downloadTextSpec : Spec Model Msg
downloadTextSpec =
  describe "downloading text"
  [ scenario "using File.Download.string" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "download-text" ]
        , Event.click
        ]
      |> it "downloads the file" (
        Spec.File.observeDownloads
          |> expect (isListWhereItemAt 0 <| satisfying
            [ Spec.File.name <| equals "funFile.txt"
            , Spec.File.text <| equals "Here is some fun text!"
            ]
          )
      )
    )
  ]


downloadUrlSpec : Spec Model Msg
downloadUrlSpec =
  describe "download url"
  [ scenario "using File.Download.url" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the url is downloaded"
        [ Markup.target << by [ id "download-url" ]
        , Event.click
        ]
      |> it "downloads the url" (
        Spec.File.observeDownloads
          |> expect (isListWhereItemAt 0 <| satisfying
            [ Spec.File.name <| equals "myUrl.txt"
            , Spec.File.downloadedUrl <| equals "http://my-fun-url.com/some/path/to/myUrl.txt"
            ]
          )
      )
    )
  ]


downloadAnchorSpec : Spec Model Msg
downloadAnchorSpec =
  describe "download url via an explicit anchor tag"
  [ scenario "a file name is specified" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView (testAnchorView "download.txt")
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "download-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "handles the click event" (
            Observer.observeModel .clicks
              |> expect (equals 1)
          )
        , it "downloads the file" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| satisfying
                [ Spec.File.name <| equals "download.txt"
                , Spec.File.downloadedUrl <| equals "http://fake.com/myFile.txt"
                ]
              )
          )
        ]
    )
  , scenario "using the filename from the server" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView (testAnchorView "")
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "download-link" ]
        , Event.click
        ]
      |> it "downloads the file" (
          Spec.File.observeDownloads
            |> expect (isListWhereItemAt 0 <| satisfying
              [ Spec.File.name <| equals "myFile.txt"
              , Spec.File.downloadedUrl <| equals "http://fake.com/myFile.txt"
              ]
            )
        )
    )
  ]


claimFailureSpec : Spec Model Msg
claimFailureSpec =
  describe "downloaded file fails claims"
  [ scenario "the file is downloaded" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "download-text" ]
        , Event.click
        ]
      |> observeThat
        [ it "gets the file name" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.name <| equals "funnyText.text")
          )
        , it "gets the file text" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.text <| equals "blah")
          )
        , it "fails to find a downloadedUrl" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.downloadedUrl <| equals "http://nowhere.com")
          )
        ]
    )
  ]


downloadUrlClaimFailureSpec : Spec Model Msg
downloadUrlClaimFailureSpec =
  describe "downloaded url fails claims"
  [ scenario "the url is downloaded" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView (testAnchorView "superFile.txt")
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "download-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "gets the file name" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.name <| equals "funnyText.text")
          )
        , it "gets the downloaded url" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.downloadedUrl <| equals "http://wrong.com")
          )
        , it "gets the file text" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.text <| equals "nothing")
          )
        ]
    )
  ]


type Msg
  = DownloadText
  | DownloadURL
  | HandleClick


type alias Model =
  { clicks: Int
  }


testModel =
  { clicks = 0
  }


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "download-text", Events.onClick DownloadText ] [ Html.text "Download File!" ]
  , Html.button [ Attr.id "download-url", Events.onClick DownloadURL ] [ Html.text "Download URL!" ]
  ]


testAnchorView : String -> Model -> Html Msg
testAnchorView filename model =
  Html.div []
  [ Html.a
    [ Attr.id "download-link"
    , Attr.download filename
    , Events.onClick HandleClick
    , Attr.href "http://fake.com/myFile.txt"
    ]
    [ Html.text "Click to download the file!" ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    DownloadText ->
      ( model, Download.string "funFile.txt" "text/plain" "Here is some fun text!" )
    DownloadURL ->
      ( model, Download.url "http://my-fun-url.com/some/path/to/myUrl.txt" )
    HandleClick ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "downloadText" -> Just downloadTextSpec
    "downloadAnchor" -> Just downloadAnchorSpec
    "downloadUrl" -> Just downloadUrlSpec
    "claimFailure" -> Just claimFailureSpec
    "downloadUrlClaimFailure" -> Just downloadUrlClaimFailureSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec
