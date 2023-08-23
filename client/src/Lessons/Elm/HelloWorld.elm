module Lessons.Elm.HelloWorld exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmIntroId
    , title = "Hello Elm"
    , body = body
    , lessonFiles = [ indexHtml, mainElm ]
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
import Html exposing (..)

main = text "Hello from Elm!"
"""


body =
    """**some** info about HTML

  - oh
  - yeah
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

