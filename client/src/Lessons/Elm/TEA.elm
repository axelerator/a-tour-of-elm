module Lessons.Elm.TEA exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmTEA
    , title = "The Elm Architecture"
    , body = body
    , lessonFiles = [ mainElm, indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = htmlIntroIndexHtml
    }


mainElm =
    { filename = "Main.elm"
    , filetype = ElmFile
    , content = mainElmContent
    }


mainElmContent =
    """module Main exposing (main)
import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

main = Browser.sandbox { init = init, update = update, view = view }

type alias Model = Int

init : Model
init = 0

type Msg = More

update : Msg -> Model -> Model
update msg model =
  case msg of
    More ->
      model + 1


view : Model -> Html Msg
view model =
  div []
    [ div [] [ text (String.fromInt model) ]
    , button [ onClick More ] [ text "+" ]
    ]
"""


body =
    """## The Elm Architecture

  """


htmlIntroIndexHtml =
    """<!DOCTYPE html>
<html>
  <head>
    <script src="main.js"></script>
  </head>
  <body>
    <div id="myapp"></div>
    <script>
    var app = Elm.Main.init({
      node: document.getElementById('myapp')
    });
    </script>
  </body>
</html>"""

