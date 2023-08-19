module Lessons.CSSIntro exposing (lesson)
import Lesson exposing (Lesson)
import Lesson exposing (Lesson(..))
import Lesson exposing (FileType(..))


lesson : Lesson
lesson =
    CSSIntro
        { indexHtml =
            { filename = "index.html"
            , filetype = HtmlFile
            , content = htmlIntroIndexHtml
            }
        , stylesCss =
            { filename = "styles.css"
            , filetype = CSSFile
            , content = stylesCSS
            }
        }


htmlIntroIndexHtml =
    """<!DOCTYPE html>
<html>
  <head>
  </head>
  <body>
    <h1>I am a red heading</h1>
    <p>I am a yellow paragraph</p>
  </body>
</html>"""

stylesCSS =
  """
h1 { color: red; }
p { background-color: yellow; }
"""


