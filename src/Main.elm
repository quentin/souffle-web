
module Main exposing (..)

import Browser exposing (Document)
import Http
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input

-- MAIN

main =
  Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type Page
  = Hello

type alias Model =
  { page : Page
  , code : String
  }

type Msg
  = Submit
  | InputChanged String

init : () -> (Model, Cmd Msg)
init _ = ( {page = Hello, code = ""} , Cmd.none)

myInput =
  Input.multiline
    [width fill]
    { label = Input.labelAbove [] (Element.text "myInput")
    , placeholder = Just (Input.placeholder [] (Element.text "input"))
    , onChange = \new -> InputChanged new
    , text = ""
    , spellcheck = False
    }

blue =
  Element.rgb255 238 238 238

mySubmit =
  Input.button
    [ Background.color blue, Border.rounded 3 ]
    {
      onPress = Just (Submit)
    , label = (text "run")
    }

view : Model -> Document Msg
view model =
  { title = 
    case model.page of
      Hello -> "Hello"

  , body =
    [ layout []
      ( case model.page of
          Hello -> hello model
      )
    ]
  }

hello model =
  column [ width fill, spacing 20 ]
    [ myInput
    , mySubmit
    , paragraph []
      [ text model.code ]
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    InputChanged str -> ( {model | code = str}, Cmd.none)
    Submit -> (model, Cmd.none)


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
