
port module Main exposing (..)

import Souffle
import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Utilities.Flex as Flex
import Browser exposing (Document)
import CodeEditor as Editor
import Html exposing (text, div, pre, p, h3)
import Html.Attributes as Attributes
import Html.Attributes exposing (src, style, class, classList)
import Html.Events
import Html.Parser
import Html.Parser.Util
import Http
import Json.Decode as D
import Json.Encode as E
import SplitPane exposing (Orientation(..), ViewConfig, createViewConfig)

-- MAIN

exampleList = ["calc","pi","foo","lang"]

main =
  Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

port setStorage : E.Value -> Cmd msg

type Page
  = Editor

type alias SouffleResult =
  { scc : String
  , output : String
  , ram : String
  }

type alias Session =
  { code : String }

type alias Model =
  { page : Page
  , result : SouffleResult
  , panes : List SplitPane.State
  , session : Session
  , menuenabled : Int
  }

type Msg
  = Submit
  | InputChanged String String
  | GotResult (Result Http.Error SouffleResult)
  | GotCode (Result Http.Error String)
  | LoadExample String
  | PaneMsg Int SplitPane.Msg
  | SelectMenu Int

init : E.Value -> (Model, Cmd Msg)
init flags =
  readFlags
    { page = Editor
    , result = {scc = "", output = "", ram = ""}
    , panes = [SplitPane.init Horizontal, SplitPane.init Horizontal]
    , session = {code = ""}
    , menuenabled = 1
    } Cmd.none flags

readFlags : Model -> Cmd msg -> E.Value -> (Model, Cmd msg)
readFlags model cmds flags =
  case D.decodeValue decodeSession flags of
    Ok session -> ({model | session = session} , cmds)
    Err _ -> (model, Cmd.batch [ setStorage (encodeSession model.session), cmds] )

decodeSession : D.Decoder Session
decodeSession =
  D.map Session
    (D.field "code" D.string)

encodeSession : Session -> E.Value
encodeSession session =
  E.object
    [ ("code", E.string session.code) ]

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

{--page model =
  div []
    [ div [class "ui sidebar inverted vertical menu visible thin"] 
      [ Html.a [class "item"] [ text "1" ]
      , Html.a [class "item"] [ text "2" ]
      ]
    , div [class "pusher"] [ editor model ]
    ]--}

editor model =
  div
    [ style "width" "100vw"
    , style "height" "100vh"
    ]
    [ case model.panes of 
        pane :: panes -> SplitPane.view (viewConfig 0) (editorView model) (secondView panes model) pane
        [] -> editorView model
    ]

viewConfig : Int -> ViewConfig Msg
viewConfig i =
  createViewConfig
    { toMsg = PaneMsg i
    , customSplitter = Nothing
    }

secondView : List SplitPane.State -> Model -> Html.Html Msg
secondView panes model =
  case panes of 
    pane :: rest -> SplitPane.view (viewConfig 1) (resultsView model) (stuffView model) pane
    [] -> (resultsView model)

resultsView : Model -> Html.Html Msg
resultsView model = 
  div [ style "overflow-y" "scroll", style "width" "100%", style "height" "100%" ]
    [ exampleSelector model
    , h3 [] [ text "Output" ]
    , outputView model
    , h3 [] [ text "SCC graph" ]
    , sccView model
    , h3 [] [ text "Initial RAM" ]
    , ramView model
    ]

stuffView : Model -> Html.Html Msg
stuffView model =
  div [ style "overflow-y" "scroll", style "width" "100%", style "height" "100%"]
      (Souffle.html (Souffle.parse model.session.code))

editorView : Model -> Html.Html Msg
editorView model =
  div [ style "width" "100%", style "height" "100%" ]
    [ div [class "ui", class "sticky", style "height" "43px !important"]
        [ div [class "ui", class "top", class "tabular", class "menu"]
            [ Html.a [classList [("item",True), ("active", model.menuenabled == 1)], Html.Events.onClick (SelectMenu 1)]
                [text "(New)"]
                {--, Html.a [classList [("item",True), ("active", model.menuenabled == 2)], Html.Events.onClick (SelectMenu 2)] [text "Tab 2" ]
                , Html.a [classList [("item",True), ("active", model.menuenabled == 3)], Html.Events.onClick (SelectMenu 3)] [text "Tab 3" ]--}
            , Html.a [class "item"] [Html.i [class "plus icon"] [] ]
            , div [class "right menu" ]
              [ div [class "ui small basic icon buttons"]
                [ Html.button [class "ui button"] [ Html.i [class "file icon"] [] ]
                , Html.button [class "ui button"] [ Html.i [class "save icon"] [] ]
                , Html.button [class "ui button"] [ Html.i [class "upload icon"] [] ]
                , Html.button [class "ui button"] [ Html.i [class "download icon"] [] ]
                ]
              , Html.button [class "ui positive right labeled icon button ", Html.Events.onClick Submit ] 
                  [ Html.i [class "right play icon"] []
                  , text "Run"
                  ]
              ]
            ]
        ]
    , codeEditor model
    ]


codeEditor model =
  Editor.codeEditor [ Editor.editorValue model.session.code, Editor.onEditorChanged (InputChanged "1" ) ] []

exampleSelector model =
  div [ class "ui menu" ]
    ( List.map
        ( \name -> Html.a 
                    [ class "item", Html.Events.onClick (LoadExample name) ] 
                    [text name]) 
        exampleList)
    
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
update msg model =
  case msg of
    LoadExample name -> ( model, (loadExample name))
    InputChanged id code -> 
      let
          newmodel = updateCode model code
      in
      ( newmodel , setStorage (encodeSession newmodel.session))
    Submit -> (submit model)
    GotResult (Ok value) -> ({model | result = value}, Cmd.none)
    GotResult (Err e) -> ({model | result = {scc = "", output = "", ram = ""}}, Cmd.none)
    GotCode (Ok code) ->
      let
          newmodel = updateCode model code
      in
      ( newmodel , setStorage (encodeSession newmodel.session))
    GotCode (Err e) -> (model, Cmd.none)
    PaneMsg num paneMsg -> ( {model | panes = updatePanes model.panes num paneMsg } , Cmd.none)
    SelectMenu i -> ( {model | menuenabled = i }, Cmd.none )

updatePanes : List SplitPane.State -> Int -> SplitPane.Msg -> List SplitPane.State
updatePanes panes pos msg =
  List.indexedMap (\i -> \pane -> if i == pos then (SplitPane.update msg pane) else pane ) panes

updateCode : Model -> String -> Model
updateCode model code =
      let
          session = model.session
          newsession = {session | code = code}
      in {model | session = newsession}

submit : Model -> (Model, Cmd Msg)
submit model =
  ( model
  , Http.post {
        url = "http://localhost:12000/run"
      , body = Http.stringBody "application/datalog" model.session.code
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
  Sub.batch
    (List.indexedMap (\i -> \pane -> ( Sub.map (PaneMsg i) <| SplitPane.subscriptions pane )) model.panes)
