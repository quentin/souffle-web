
module Main exposing (..)

import Browser exposing (Document)
import Http
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Grid as Grid
import Bootstrap.Form.Textarea as Textarea
import Html exposing (text, div, pre)
import Html.Attributes as Attributes
import CodeEditor as Editor

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

type alias Model =
  { page : Page
  , code : String
  , result : String
  }

type Msg
  = Submit
  | InputChanged String
  | GotResult (Result Http.Error String)
  | LoadFooExample

init : () -> (Model, Cmd Msg)
init _ =
  ( { page = Editor
    , code = ""
    , result = ""
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
  Grid.container []
      [ Grid.row []
          [ Grid.col [] [ Editor.codeEditor [ Editor.editorValue model.code, Editor.onEditorChanged InputChanged ] [] ] ]
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
          [ Grid.col [] [ pre [Attributes.style "background-color" "gray", Attributes.disabled True] [text model.result] ] ]
      ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LoadFooExample -> ( {model | code = fooExample}, Cmd.none )
    InputChanged str -> ( {model | code = str}, Cmd.none)
    Submit -> (submit model)
    GotResult (Ok value) -> ({model | result = value}, Cmd.none)
    GotResult (Err e) -> ({model | result = "Error :("}, Cmd.none)

submit : Model -> (Model, Cmd Msg)
submit model =
  ( model
  , Http.post {
        url = "http://localhost:12000/run"
      , body = Http.stringBody "application/datalog" model.code
      , expect = Http.expectString GotResult }
  )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
