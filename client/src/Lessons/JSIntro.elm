module Lessons.JSIntro exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = JSIntroId
    , title = "Variables and Statements"
    , body = body
    , lessonFiles = [ indexHtml ]
    }

body = """# Variables and Statements

JavaScript is an _imperative_ languge. It uses **statments** to tell the browser what to do.
We can add a `<script>` element to provide the browser with a sequence of statements to execute.

Our example on the right contains three _statements_.

1. It tells the browser we want to register a new _variable_ called `yummy`
   That is like a placeholder that we can reuse in later statements. And this placeholder should from now
   on represent the text `apple`.
2. The second statement introduces a second variable `more_yummy` which stands for whatever `yummy` contained
   concatenated (fancy word for "smushed together").
3. The last statment tells the browser to execute the `alert` function which opens a little pop up window.
   The popup window will contain whatever we put in between the `(...)` after the `alert`. In out case whatever
   the `more_yummy` variable contained concatenated with the text `vinegar`.

### Exercise

Change the code so that the pop up says _"Delicious apple cider vinegar"_!

"""


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }

html =
    """<html>
  <body>
    <script>
      let yummy = "apple"
      let more_yummy = yummy + " cider"
      alert(more_yummy + " vinegar")
    </script>
  </body>
</html>"""
