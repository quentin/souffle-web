
module CodeEditor exposing
  ( codeEditor
  , editorValue
  , onEditorChanged
  )

import Html exposing (Attribute, Html)
import Html.Attributes exposing (property)
import Html.Events exposing (on)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)

codeEditor : List (Attribute msg) -> List (Html msg) -> Html msg
codeEditor =
  Html.node "code-editor"

editorValue : String -> Attribute msg
editorValue value =
  property "editorValue" <|
    JE.string value

onEditorChanged : (String -> msg) -> Attribute msg
onEditorChanged tagger =
  on "editorChanged" <|
    JD.map tagger <|
      JD.at [ "target", "editorValue" ]
        JD.string
