module Lessons.CSSInclude exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = CSSIncludeId
    , title = "External Stylesheets"
    , body = body
    , lessonFiles = [ indexHtml, stylesCss, altStylesCss ]
    }


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


altStylesCss =
    { filename = "alt_styles.css"
    , filetype = CSSFile
    , content = altStylesCSS
    }


body =
    """# Including external stylesheets

A website rarely consists of a single document. Each page is a dedicated HTML
document reachable through a distinct URL. To be able to give our readers a
consitent _look and feel_ we'll want to **reuse** our list of CSS rules.

Again we can make use of the browsers feature to _pull in_ external files from
our document. All we have to do is:

1. Store our CSS rules in a new stylesheet file 
2. Find the URL under which we can find the file 
3. Point from our HTML document to that URL

In the editor on the right you'll notice there are several tabs now. Next to
the `index.html` there is now also two stylesheets called containing some CSS
rules.

To point our HTML document to the stylesheet we have to learn about the
`<link>` element.

The [link
element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link) has a
`href` attribute that lets us specify a `URL` to an external resource.

In our example it just says `"styles.css"`. This does not look like a URL at
all! How does it know from which server or domain to download the file!?🤯

The URL does not start with `https://...` so that means the browser will look
on the same server it got the `index.html` from. This _relative_ lookup is
super handy. Because it means whenever we place these to files in the same
folder, the browser will always find the `styles.css` _relative_ to the
`index.html`.

### Exercise

Change the URL in the `<link>` element to point to the `alt_styles.css` instead.
Hit run to see how now the rules of the second stylesheet are applied.

What happens if you link both stylesheets?
"""


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
p { 
  background-color: yellow; 
}
"""


altStylesCSS =
    """
h1 { color: blue; }
"""
