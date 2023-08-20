module Lessons.CSSIntro exposing (lessonDescription)

import Lesson exposing (FileType(..), LessonId(..))


lessonDescription =
    { id = CSSIntroId
    , title = "Hello CSS"
    , body = body
    , lessonFiles = [ indexHtml, stylesCss ]
    }


body =
    """**some** markdown

  - oh
  - yeah
  """


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = htmlIntroIndexHtml
    }


stylesCss =
    { filename = "styles.css"
    , filetype = CSSFile
    , content = stylesCSS
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
