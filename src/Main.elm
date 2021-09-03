
module Main exposing (..)

import Browser exposing (Document)
import Http
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Grid as Grid
import Bootstrap.Form.Textarea as Textarea
import Html exposing (text, div, pre, p)
import Html.Attributes as Attributes
import CodeEditor as Editor
import Html.Parser
import Html.Parser.Util
import Json.Decode as D

-- MAIN

fooExample = "/* the foo rule*/\n.decl foo( /*attribute*/ a:number, b:symbol)\n.output foo\n\nfoo(1,\"2\").\nfoo(4,\"4\").\nfoo(33,\"large\").\n\n.decl query(a:number)\n.output query\n\nquery(n) :- foo(n,_), n < 10."

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
  }

type alias Model =
  { page : Page
  , code : String
  , result : SouffleResult
  }

type Msg
  = Submit
  | InputChanged String String
  | GotResult (Result Http.Error SouffleResult)
  | LoadFooExample

init : () -> (Model, Cmd Msg)
init _ =
  ( { page = Editor
    , code = ""
    , result = {scc = "",output = ""}
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
  let
      -- convert the received <img> of the program SCC to virtual-dom value
      scc = case (Html.Parser.run model.result.scc) of
        Ok val -> Html.Parser.Util.toVirtualDom val
        Err _ -> []
  in
  Grid.containerFluid []
      [ Grid.row []
          [ Grid.col [] [ Editor.codeEditor [ Editor.editorValue model.code, Editor.onEditorChanged (InputChanged "1" ) ] [] ] ]
      , Grid.row []
          [ Grid.col []
            [ ButtonGroup.buttonGroup []
              [ ButtonGroup.button
                [ Button.primary , Button.onClick Submit ]
                [ text "Run" ]
              , ButtonGroup.button
                  [ Button.onClick LoadFooExample ]
                  [ text "Load Foo" ]
              ]
            ]
          ]
      , Grid.row []
          [ Grid.col [] [ pre [Attributes.style "background-color" "gray", Attributes.disabled True] [text model.result.output] ] ]
      , Grid.row []
          [ Grid.col [] scc ]
      ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LoadFooExample -> ( {model | code = fooExample}, Cmd.none )
    InputChanged id str -> ( {model | code = str}, Cmd.none)
    Submit -> (submit model)
    GotResult (Ok value) -> ({model | result = value}, Cmd.none)
    GotResult (Err e) -> ({model | result = {scc = "", output = ""}}, Cmd.none)

submit : Model -> (Model, Cmd Msg)
submit model =
  ( model
  , Http.post {
        url = "http://localhost:12000/run"
      , body = Http.stringBody "application/datalog" model.code
      , expect = Http.expectJson GotResult souffleResultDecoder }
  ) 

souffleResultDecoder : D.Decoder SouffleResult
souffleResultDecoder =
  D.map2 SouffleResult
    (D.field "scc" D.string)
    ( D.field "output" D.string )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
