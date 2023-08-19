module Lessons.HtmlIntro exposing (lesson)
import Lesson exposing (Lesson)
import Lesson exposing (Lesson(..))
import Lesson exposing (FileType(..))

lesson : Lesson
lesson =
    HtmlIntro
        { indexHtml =
            { filename = "index.html"
            , filetype = HtmlFile
            , content = htmlIntroIndexHtml
            }
        }


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

