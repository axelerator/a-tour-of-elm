module Lessons.Elm.HelloWorld exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmIntroId
    , title = "Hello Elm"
    , body = body
    , lessonFiles = [ indexHtml, mainElm ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = htmlIntroIndexHtml
    }


mainElm =
    { filename = "Main.elm"
    , filetype = ElmFile
    , content = mainElmContent
    }


mainElmContent =
    """module Main exposing (main)
import Html exposing (..)

main = text "Hello from Elm!"
"""


body =
    """## Hello Elm 👋

The browser itself does not understand Elm. We have to use the _Elm compiler_ to _translate_ aka _compile_
our Elm program to JavaScript.

But with **just** JavaScript the browser still can't display anything. We have to give the browser our 
_"single (HTML) page"_ of our _Single Page Application_.

This page can then pull in our compiled JavaScript to replace/modify that page.

And the files in this lesson are the minimal setup to achieve this.

When you hit run we execute this command from the [Elm guide](https://guide.elm-lang.org/interop/#compiling-to-javascript)
on your behalf. The result is a _new_ file `main.js` that contains the _compiled_ version of the `main.elm` file.

In the `<head>` section of the `index.html` we _include_ that `main.js` and it's content gets loaded by the browser.

Loading that code makes our app "available" to the current page but doesn't execute/do anything just yet.

The magic \u{1FA84} happens in the second `<script>` block. Here we tell the browser to _execute_ or _call_ the `init` function
of something that's called `Elm.Main` which has been made availbe through the inclusion of the `main.js`.

When we call `init` we have to tell which part of the page we want to replace with the content of our Elm application.
The `node: document.getElementById('myapp')` looks for an element with the `id` attribute with the value `myapp`.

By "handing" this element over to the `Elm.Main.init` call we give Elm an "entry point" into our document and it replaces
that element with the content of our Elm application.

The `Main.elm` contains the simplest Elm application one can think of. It just displays a static text.

## Exercise

1. Elm works exclusively on the element we give it. Add other elements to the page to see how they interact!

2. You can even use the same app multiple times! Add a new element with the `id="secondapp"` and call init a second time to replace that new container. 
  """


htmlIntroIndexHtml =
    """<!DOCTYPE html>
<html lang="en">
  <head>
    <title>My Elm app</title>
    <script src="main.js"></script>
  </head>
  <body>
    <div id="myapp"></div>
    <script>
    var app = Elm.Main.init({
      node: document.getElementById('myapp')
    });
    </script>
  </body>
</html>"""
