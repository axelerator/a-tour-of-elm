module Lessons.ElmIntro exposing (lessonDescription)

import Lesson exposing (FileType(..), LessonId(..))


lessonDescription =
    { id = ElmIntroId
    , title = "Hello Elm"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = htmlIntroIndexHtml
    }


body =
    """**some** info about HTML

  - oh
  - yeah
  """


htmlIntroIndexHtml =
    """<!DOCTYPE html>
<html>
  <head>
    <title>Hello HTML</title>
  </head>
  <body>
    <p>I am a paragraph</p>
  </body>
</html>"""
