module Lessons.HtmlIntro exposing (lesson, lessonDescription)
import Lesson exposing (Lesson)
import Lesson exposing (Lesson(..))
import Lesson exposing (FileType(..))
import Lesson exposing (LessonId(..))

lessonDescription =
    { id = HtmlIntroId
    , title = "Hello Html"
    , body = body
    , lesson = lesson
    }

lesson : Lesson
lesson =
    HtmlIntro
        { indexHtml =
            { filename = "index.html"
            , filetype = HtmlFile
            , content = htmlIntroIndexHtml
            }
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

