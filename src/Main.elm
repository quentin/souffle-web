
port module Main exposing (..)

import Souffle
import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Utilities.Flex as Flex
import Dict exposing (Dict)
import Browser exposing (Document)
import CodeEditor as CodeEditor
import Html exposing (text, div, pre, p, h3)
import Html.Attributes as Attributes
import Html.Attributes exposing (src, style, class, classList)
import Html.Events
import Html.Parser
import Html.Parser.Util
import Http
import Json.Decode as D
import Json.Decode.Extra exposing (dict2)
import Json.Encode as E
import SplitPane exposing (Orientation(..), ViewConfig, createViewConfig)

-- MAIN

exampleList = ["calc","pi","foo","lang", "ski"]

main =
  Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

port setStorage : E.Value -> Cmd msg
port openBuffer : { name:String, text:String, mode:String } -> Cmd msg
port selectBuffer: { editorId:String, bufferId:String } -> Cmd msg
port closeBuffer: String -> Cmd msg

type Page
  = Editor

type alias SouffleResult =
  { scc : String
  , output : String
  , ram : String
  }

type alias CodeBuffer =
  { code : String
  , name : String
  , mode : String
  }

type alias Session =
  { buffers : Dict Int CodeBuffer
  , selectedBuffer : Int
  }

type alias Model =
  { page : Page
  , result : SouffleResult
  , panes : List SplitPane.State
  , session : Session
  , menuenabled : Int
  }

type Msg
  = Submit
  | InputChanged Int String
  | GotResult (Result Http.Error SouffleResult)
  | GotCode (Result Http.Error String)
  | LoadExample String
  | PaneMsg Int SplitPane.Msg
  | SelectBuffer Int
  | NewBuffer
  | CloseBuffer Int

init : E.Value -> (Model, Cmd Msg)
init flags =
  readFlags
    { page = Editor
    , result = {scc = "", output = "", ram = ""}
    , panes = [SplitPane.init Horizontal, SplitPane.init Horizontal]
    , session =
        { buffers =
              Dict.fromList[ (1, { name = "*scratch*", code = "", mode = "souffle" }) ]
        , selectedBuffer = 1
        }
    , menuenabled = 1
    } Cmd.none flags

readFlags : Model -> Cmd msg -> E.Value -> (Model, Cmd msg)
readFlags model cmds flags =
  case D.decodeValue decodeSession flags of
    Ok session ->
      (
        {model | session = session} ,
        Cmd.batch
          ( cmds :: (List.map
            (\couple -> let (id,{code,name,mode}) = couple in openBuffer({name = String.fromInt id, text = code, mode = mode}))
            (Dict.toList session.buffers)))
      )
    Err _ ->
      ( model
      , Cmd.batch
          ( (setStorage (encodeSession model.session)) ::
            cmds ::
            (List.map
              (\couple -> let (id,{code,name,mode}) = couple in openBuffer({name = String.fromInt id, text = code, mode = mode}))
              (Dict.toList model.session.buffers)))
      )

decodeSession : D.Decoder Session
decodeSession =
  D.map2 Session
    (D.field "buffers"
      (dict2 (D.int) decodeCodeBuffer))
    (D.field "selectedBuffer" D.int)

decodeCodeBuffer : D.Decoder CodeBuffer
decodeCodeBuffer =
  D.map3 CodeBuffer
    (D.field "code" D.string)
    (D.field "name" D.string)
    (D.field "mode" D.string)

encodeSession : Session -> E.Value
encodeSession session =
  E.object
  [ ( "buffers", E.dict String.fromInt encodeCodeBuffer session.buffers )
  , ( "selectedBuffer", E.int session.selectedBuffer )
  ]

encodeCodeBuffer : CodeBuffer -> E.Value
encodeCodeBuffer buffer =
  E.object
    [ ("code", E.string buffer.code)
    , ("name", E.string buffer.name)
    , ("mode", E.string buffer.mode)
    ]

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
      (Souffle.html
        (Souffle.parse (currentBufferCode model.session)))

currentBufferCode : Session -> String
currentBufferCode session =
  Maybe.withDefault ""
    (Maybe.map
      (\buffer -> buffer.code)
      (Dict.get session.selectedBuffer session.buffers))

currentBufferName : Session -> String
currentBufferName session =
  Maybe.withDefault ""
    (Maybe.map
      (\buffer -> buffer.name)
      (Dict.get session.selectedBuffer session.buffers))

bufferTabsView : Session -> List (Html.Html Msg)
bufferTabsView session =
  Dict.foldr (\id -> \buffer -> \list -> (bufferTabItemView id buffer (session.selectedBuffer == id)) :: list ) [] session.buffers

bufferTabItemView : Int -> CodeBuffer -> Bool -> Html.Html Msg
bufferTabItemView id buffer selected =
  Html.a
    [ classList 
      [ ("item",True)
      , ("active", selected)
      ]
    , Html.Events.onClick (SelectBuffer id)
    ]
    [ text buffer.name
    , Html.i
      [ class "close icon"
      , Html.Events.stopPropagationOn "click" (D.succeed (CloseBuffer id, True))
      ]
      []
    ]

editorView : Model -> Html.Html Msg
editorView model =
  div [ style "width" "100%", style "height" "100%" ]
    [ div
        [class "ui"
        , class "sticky"
        , style "height" "43px !important"
        , style "top" "0"
        , style "left" "0"
        , style "right" "0"
        , style "overflow" "hidden"
        , style "position" "absolute"
        , style "overflow-x" "auto"
        ]
        [ div [class "ui", class "top", class "tabular", class "menu"]
            ( List.append
                (bufferTabsView model.session)
                [ Html.a [class "item", Html.Events.onClick (NewBuffer)] [Html.i [class "plus icon"] [] ]
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
            )
        ]
    , div
        [ style "overflow-y" "auto"
        , style "top" "43px"
        , style "bottom" "0"
        , style "overflow" "hidden"
        , style "position" "absolute"
        , style "left" "0"
        , style "right" "0"
        ]
        [(codeEditor model.session)]
    ]


codeEditor session =
  CodeEditor.view
    [ CodeEditor.id "ed_left"
    , CodeEditor.value (currentBufferCode session)
    , CodeEditor.onChange (InputChanged session.selectedBuffer )
    ]

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
    InputChanged bufferId code ->
      let
          newsession = updateCode model.session bufferId code
          newmodel = { model | session = newsession }
      in
      ( newmodel , setStorage (encodeSession newsession))

    Submit -> (submit model)

    GotResult (Ok value) -> ({model | result = value}, Cmd.none)

    GotResult (Err e) -> ({model | result = {scc = "", output = "", ram = ""}}, Cmd.none)

    GotCode (Ok code) ->
      let
          newsession = updateCode model.session model.session.selectedBuffer code
          newmodel = { model | session = newsession }
      in
      ( newmodel , setStorage (encodeSession newsession))

    GotCode (Err e) -> (model, Cmd.none)

    PaneMsg num paneMsg -> ( {model | panes = updatePanes model.panes num paneMsg } , Cmd.none)

    SelectBuffer i ->
      let
          session = model.session
          newsession = { session | selectedBuffer = i }
      in
      ( {model | session = newsession }, 
        Cmd.batch
          [ setStorage (encodeSession newsession)
          , selectBuffer {editorId = "ed_left", bufferId = String.fromInt i}
          ]
      )

    NewBuffer ->
      let
          session = model.session
          bufferId = Dict.foldl (\id -> \_ -> \res -> max res (id+1)) 1 session.buffers
          bufferName = String.concat [ "*scratch-" , String.fromInt bufferId , "*"]
          newbuffers = Dict.insert bufferId {code = "", name = bufferName, mode = "souffle"} session.buffers
          newsession = { session | buffers = newbuffers }
          newmodel = { model | session = newsession }
      in
      ( newmodel
      , Cmd.batch
        [ openBuffer
          { name = String.fromInt bufferId
          , text = ""
          , mode = "souffle"
          }
        , setStorage (encodeSession newsession)
        ]
      )

    CloseBuffer i ->
      let
          session = model.session
          newbuffers = Dict.remove i session.buffers
          newSelectedBuffer =
            if session.selectedBuffer == i
            then 1
            else session.selectedBuffer
          newsession = { session | buffers = newbuffers, selectedBuffer = newSelectedBuffer }
          newmodel = { model | session = newsession }
      in
      ( newmodel
      , Cmd.batch
        [ selectBuffer { editorId = "ed_left", bufferId = String.fromInt newSelectedBuffer }
        , closeBuffer (String.fromInt i)
        , setStorage (encodeSession newsession)
        ]
      )

updatePanes : List SplitPane.State -> Int -> SplitPane.Msg -> List SplitPane.State
updatePanes panes pos msg =
  List.indexedMap (\i -> \pane -> if i == pos then (SplitPane.update msg pane) else pane ) panes

updateCode : Session -> Int -> String -> Session
updateCode session bufferId newCode =
  let
      newBuffers = Dict.update bufferId
        ( Maybe.map (\buffer -> {buffer | code = newCode}))
        session.buffers
  in
  { session | buffers = newBuffers }

submit : Model -> (Model, Cmd Msg)
submit model =
  ( model
  , Http.post {
        url = "/run"
      , body = Http.stringBody "application/datalog" (currentBufferCode model.session)
      , expect = Http.expectJson GotResult souffleResultDecoder }
  )

loadExample : String -> Cmd Msg
loadExample name =
  Http.get
  {
    url = "/assets/example-" ++ name ++ ".dl",
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
