module Souffle exposing (parse, html)

import Parser exposing 
  ( Parser
  , Problem (..)
  , oneOf
  , chompIf
  , Nestable (..)
  , DeadEnd
  , chompWhile
  , chompUntilEndOr
  , chompUntil
  , getChompedString
  , getPosition
  , symbol
  , loop
  , map
  , Step (..)
  , spaces
  , succeed
  , (|.)
  , (|=)
  )
import Parser.Advanced
import Html

parse : String -> Pieces
parse code = 
  case Parser.run pieces code of
    Ok p -> p
    Err e -> [Erroneous e]

html : Pieces -> List (Html.Html msg)
html pcs =
  List.map render pcs

type alias Located a =
  { start : (Int, Int)
  , value : a
  , end : (Int, Int)
  }

located : (Int,Int) -> a -> (Int,Int) -> Located a
located start value end =
  {start=start, value=value, end=end}

type Piece
  = Comment (Located String)
  | Space (Located String)
  | Code (Located String)
  | Erroneous (List Parser.DeadEnd)

type AST
  = Other String

type alias Pieces = List Piece

render : Piece -> (Html.Html msg)
render piece =
  Html.div []
  [case piece of
    Comment {value} -> Html.text (" Comment(" ++ value ++ ")")
    Code {value} -> Html.text ("Code(" ++ value ++ ")")
    Space {value} -> Html.text (" Space(" ++ value ++ ")")
    Erroneous e -> Html.text (deadEndsToString e)]

deadEndsToString : List DeadEnd -> String
deadEndsToString errs =
  case errs of
    [] -> "no error"
    err :: moreerrs -> "at line " ++ (String.fromInt err.row)
      ++ " column " ++ (String.fromInt err.col) ++ ": " ++ (problemToString err.problem)

problemToString problem =
  case problem of
    Parser.Expecting s -> "expecting " ++ s
    Parser.ExpectingEnd -> "expecting End"
    Parser.UnexpectedChar -> "unexpected character"
    Parser.Problem s -> s
    Parser.BadRepeat -> "bad repeat"
    _ -> "other"

pieces : Parser Pieces
pieces =
  loop [] stepPiece

stepPiece : Pieces -> Parser (Step Pieces Pieces)
stepPiece revPieces =
  oneOf
    [ Parser.end
        |> map (\_ -> Done (List.reverse revPieces))
    , (locatedParser parseSpaces)
        |> map (\v -> Loop ((Space v) :: revPieces))
    , (locatedParser parseLineComment)
        |> map (\v ->
          Loop 
            ((Comment v) :: revPieces))
    , (locatedParser parseMultiComment)
        |> map (\v ->
          Loop 
            ((Comment v) :: revPieces))
    , (locatedParser parseCode)
        |> map (\v -> Loop ((Code v) :: revPieces))
    ]

parseSpaces : Parser String
parseSpaces =
  getChompedString
      (chompOneOrMore (\c -> c == ' ' || c == '\n' || c == '\t' || c == '\r'))

parseLineComment : Parser String
parseLineComment =
  getChompedString
    (symbol "//" |. chompUntilEndOr "\n")
  |> map (\s -> String.dropLeft 2 s)

parseMultiComment : Parser String
parseMultiComment =
  getChompedString
    (symbol "/*" |. chompUntil "*/" |. symbol "*/")
  |> map (\s -> (String.dropLeft 2 (String.dropRight 2 s)))

parseCode : Parser String
parseCode = 
  getChompedString
    (oneOf
      [ symbol "/"
      , chompUntilEndOr "/"
      ]
    )

chompOneOrMore : (Char -> Bool) -> Parser ()
chompOneOrMore p =
  succeed ()
    |. chompIf p
    |. chompWhile p

locatedParser : (Parser a) -> Parser (Located a)
locatedParser parser =
  succeed Located 
    |= getPosition 
    |= parser
    |= getPosition

