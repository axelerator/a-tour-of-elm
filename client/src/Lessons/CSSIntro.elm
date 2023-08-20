module Lessons.CSSIntro exposing (lesson, lessonDescription)

import Lesson exposing (FileType(..), Lesson(..), LessonId(..))
import Lessons.HtmlIntro exposing (lesson)


lessonDescription =
    { id = CSSIntroId
    , title = "Hello CSS"
    , body = body
    , lesson = lesson
    }


body =
    """**some** markdown

  - oh
  - yeah
  """


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
    <link rel="stylesheet" href="styles.css">
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
