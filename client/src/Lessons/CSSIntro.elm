module Lessons.CSSIntro exposing (lessonDescription)

import Lesson exposing (FileType(..), LessonId(..))


lessonDescription =
    { id = CSSIntroId
    , title = "Inline Styles"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


body =
    """# Very stylish!

To modify how our HTML elements are displayed we can use their `style` attribute.
In the _value_ (the part after the `=`) we can list **CSS properties**.

These properties like `color` and `font size` will then affect how that element is displayed.

### Exercise

Look at other properties like [font-size](https://developer.mozilla.org/en-US/docs/Web/CSS/font-size) or [border](https://developer.mozilla.org/en-US/docs/Web/CSS/border) 
and apply them to the existing elements on the right (or add new ones) to change their visual appearance.
  """


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }


html =
    """<html>
  <body>
    <h1 style="color: red">I am a red heading</h1>
    <p style="background-color: yellow; text-decoration: underline">I am a yellow paragraph</p>
  </body>
</html>"""
