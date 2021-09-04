
module Main exposing (..)

import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Utilities.Flex as Flex
import Browser exposing (Document)
import CodeEditor as Editor
import Html exposing (text, div, pre, p)
import Html.Attributes as Attributes
import Html.Attributes exposing (src, style)
import Html.Parser
import Html.Parser.Util
import Http
import Json.Decode as D
import SplitPane exposing (Orientation(..), ViewConfig, createViewConfig)

-- MAIN

exampleList = ["calc","pi","foo"]

main =
  Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type Page
  = Editor

type alias SouffleResult =
  { scc : String
  , output : String
  , ram : String
  }

type alias Model =
  { page : Page
  , code : String
  , result : SouffleResult
  , pane : SplitPane.State
  }

type Msg
  = Submit
  | InputChanged String String
  | GotResult (Result Http.Error SouffleResult)
  | GotCode (Result Http.Error String)
  | LoadExample String
  | PaneMsg SplitPane.Msg

init : () -> (Model, Cmd Msg)
init _ =
  ( { page = Editor
    , code = ""
    , result = {scc = "", output = "", ram = ""}
    , pane = SplitPane.init Horizontal
    }
  , Cmd.none
  )

view : Model -> Document Msg
view model =
  { title =
    case model.page of
      Editor -> "Editor"

  , body = [
    ( case model.page of
      Editor -> editor model
    )]
  }

editor model =
  div
    [ style "width" "100vw"
    , style "height" "100vh"
    ]
    [ SplitPane.view viewConfig (editorView model) (resultsView model) model.pane ]

viewConfig : ViewConfig Msg
viewConfig =
  createViewConfig
    { toMsg = PaneMsg
    , customSplitter = Nothing
    }

resultsView : Model -> Html.Html Msg
resultsView model = 
  div [ style "overflow-y" "scroll", style "width" "100%"]
    [ Card.config []
      |> Card.block [] (buttonBar model)
      |> Card.view
    , Card.config [] 
      |> Card.header [] [ text "Output" ]
      |> Card.block [] [ Block.custom <| (outputView model) ]
      |> Card.view
    , Card.config []
      |> Card.header [] [ text "SCC graph" ]
      |> Card.block [] [ Block.custom <| (sccView model) ]
      |> Card.view
    , Card.config []
      |> Card.header [] [ text "Initial RAM" ]
      |> Card.block [] [ Block.custom <| (ramView model) ]
      |> Card.view
    ]

editorView : Model -> Html.Html Msg
editorView model =
  codeEditor model


codeEditor model =
  Editor.codeEditor [ Editor.editorValue model.code, Editor.onEditorChanged (InputChanged "1" ) ] []

buttonBar model =
  [ Block.custom <|
    ButtonGroup.buttonGroup []
    (
      (ButtonGroup.button
        [ Button.primary , Button.onClick Submit ]
        [ text "Run" ]
      )
      ::
      exampleSelector
    )
  ]

exampleSelector =
  List.map (\name -> ButtonGroup.button [ Button.onClick (LoadExample name) ] [text name]) exampleList

outputView model =
    pre [Attributes.style "background-color" "#F8F8F8", Attributes.disabled True] [text model.result.output]

sccView model =
  -- convert the received <img> of the program SCC to virtual-dom value
  div []
  (case (Html.Parser.run model.result.scc) of
    Ok val -> Html.Parser.Util.toVirtualDom val
    Err _ -> [])

ramView model =
  pre [Attributes.style "background-color" "#F8F8F8", Attributes.disabled True] [text model.result.ram]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =-->
  case msg of
    LoadExample name -> ( model, (loadExample name))
    InputChanged id str -> ( {model | code = str}, Cmd.none)
    Submit -> (submit model)
    GotResult (Ok value) -> ({model | result = value}, Cmd.none)
    GotResult (Err e) -> ({model | result = {scc = "", output = "", ram = ""}}, Cmd.none)
    GotCode (Ok code) -> ({model | code = code}, Cmd.none)
    GotCode (Err e) -> (model, Cmd.none)
    PaneMsg paneMsg -> ( {model | pane = SplitPane.update paneMsg model.pane } , Cmd.none)

submit : Model -> (Model, Cmd Msg)
submit model =
  ( model
  , Http.post {
        url = "http://localhost:12000/run"
      , body = Http.stringBody "application/datalog" model.code
      , expect = Http.expectJson GotResult souffleResultDecoder }
  )

loadExample : String -> Cmd Msg
loadExample name =
  Http.get
  {
    url = "http://localhost:12000/assets/example-" ++ name ++ ".dl",
    expect = Http.expectString GotCode
  }

souffleResultDecoder : D.Decoder SouffleResult
souffleResultDecoder =
  D.map3 SouffleResult
    (D.field "scc" D.string)
    (D.field "output" D.string)
    (D.field "ram" D.string)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.map PaneMsg <| SplitPane.subscriptions model.pane
