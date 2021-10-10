
module CodeEditor exposing
  ( id
  , view
  , value
  , onChange
  )

import Html exposing (Attribute, Html)
import Html.Attributes exposing (property)
import Html.Events exposing (on)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)

type Attribute msg
  = Attr (Html.Attribute msg)

unattr : Attribute msg -> Html.Attribute msg
unattr (Attr a) =
  a

view: List (Attribute msg) -> Html msg
view attributes =
  Html.node "code-editor" (List.map unattr attributes) []

value : String -> Attribute msg
value =
  JE.string >> property "editorValue" >> Attr

id : String -> Attribute msg
id =
  Html.Attributes.id >> Attr

onChange : (String -> msg) -> Attribute msg
onChange tagger =
  Attr <| on "change" (JD.map tagger (JD.at ["target","editorValue" ] JD.string))

