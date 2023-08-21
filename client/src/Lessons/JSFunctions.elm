module Lessons.JSFunctions exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = JSFunctionsId
    , title = "Functions and external scripts"
    , body = body
    , lessonFiles = [ indexHtml, functionsJs ]
    }

body = """# Functions and external scripts

Similarly how we used CSS rules and stylesheets to reuse our code we can use
**functions** and **script files** to achieve the same effect for JavaScript.

In the `HTML` document you see we now have a `<script>` element with a `src`
attribute, telling it to first load the external script `my-functions.js`.

This file is in the other tab and it declares _a function_ called `acidify`.

``` let acidify = (something) => something + " vinegar" ```

We use the `let` to define a new variable. But instead it being a "placeholder"
    for a value it is now a placeholder for a "calulation". Because we have the
    `(...) => ` part after the `=` sign the browser knows we have to give it
    "something" to be able to replace later uses of `acidify`.

In the second `<script>` block in the `index.html` we tell the browser to
_execute_ the `acidify` and give the result to the alert function each time.

The first time the something we pass to the `acidify` function is the text
`apple`. 

### Exercise

Can you modify the second of the alert calls to use the `fruit` variable
instead so that the pop up says `Melon vingar`?
"""

indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }

functionsJs =
    { filename = "my-functions.js"
    , filetype = JSFile
    , content = js
    }

js = """let acidify = (something) => something + " vinegar"
let fruit = "melon"
"""


html =
    """
<html>
  <head> 
    <script src="my-functions.js"></script>
    <script>
      alert(acidify("apple cider"))
      alert(acidify("white wine"))
    </script>
  </head>
</html>"""

