module Lessons.HtmlAttributes exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = HtmlAttributesId
    , title = "Attributes"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }


body =
    """# Attributes & void elements

Before we look at attributes I want to mentions a special flavour of elements
called _"void elements"_. Contrary to regular elements they can't have any
content.

One example is the `<input>` tag. So **instead** of writing:

```xml 
<input></input> 
```

We can simply omit the closing tag. So the following has the exact same meaning:

```xml 
<input>
```

### Attributes

To add information about an element _itself_ rather than just adding content we
can add an **attribute** to an HTML element.

On the right you see a HTML document with only an `input` element in it's body.
But before the ending `>` of the _opening_ tag there is the `type` attribute
specifying that this input is a "text input" by the expression `type="text"`.

Different _elements_ allow different types of attributes and their values.
Other valid values for the `type` attribute of an `input` elements are
`number`, `date` and `color`.

Try changing the input's `type` or add more input elements with different types
to see how it affects the behaviour of the element.

For a comprehensive description of input elements see [their
documentation](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#input_types).
    """


html =
    """<html lang="en">
  <head>
    <title>My document</title>
  </head>
  <body>
    <input type="text">
  </body>
</html>"""
