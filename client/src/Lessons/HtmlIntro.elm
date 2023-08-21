module Lessons.HtmlIntro exposing (lessonDescription)

import Lesson exposing (FileType(..), LessonId(..))


lessonDescription =
    { id = HtmlIntroId
    , title = "Tags & Elements"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = htmlIntroIndexHtml
    }


body =
    """# My first HTML document

To be able to understand the jargon around web apps we need to get familiar with names developers
use for certain concepts.

## Elements and tags

A `HTML` document is made up of **elements**. For example an element to display a paragraph is called just `p`
and looks like this:

```html
<p>some text</p>
```

The `p` with it surrounding pointy brackets are called tags. So an element is composed of

- an _opening_ tag (`<p>`)
- it content (here the text `some text`)
- and a _closing_ tag (`</p>` - note the extra slash `/`)

## Trees and the DOM

The content of an element cannot only be text but also other elements 🤯!
When we put elements into other elements we call that _nesting_.

When we _nest_ a lot of elements, and we think of the outer as "bigger" elements, while the
inner ones get smaller and we squint a lot, we get why computer scientists like to call
the resulting structure a tree.

This specific tree as it can be contructed from HTML elements is officially also called The
[Document Object Model (DOM)](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model).

In the editor on the right is a minimal example of a tree of elements forming a DOM.
HTML is the DOM that the browser is made to display.

Click "run" to see how the browser diplays this `HTML` document in the bottom right panel.

Here is an image showing how the nested elements can be thought of as "branches" of a tree.

![a treelike representation of the document](/assets/images/tree.svg)
  """


htmlIntroIndexHtml =
    """
<html>
  <body>
    <h1>I am a heading!</h1>
    <p>I am a paragraph</p>
    <ul>
      <li>We</li>
      <li>are</li>
      <li>items</li>
      <li>in a list</li>
    </ul>
  </body>
</html>"""
