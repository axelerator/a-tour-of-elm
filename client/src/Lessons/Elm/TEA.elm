module Lessons.Elm.TEA exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmTEA
    , title = "The Elm Architecture"
    , body = body
    , lessonFiles = [ mainElm, indexHtml ]
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
import Browser
import Html exposing (Html, button, p, text)
import Html.Events exposing (onClick)

view currentNumber = p [] [currentNumberAsText currentNumber, moreButton, lessButton]

moreButton = button [onClick More] [text "more"]
lessButton = button [onClick Less] [text "less"]

currentNumberAsText number = text (String.fromInt number)

type Msg = More | Less

update msg currentNumber =
  case msg of
      More -> currentNumber + 1
      Less -> currentNumber - 1

main = Browser.sandbox { view = view, update = update, init = 99 }
"""


body =
    """## The Elm Architecture

So far we've only dealt with the "language" part of Elm. To create our first app we have to understand 
the part that's played by the "framework" (i.e. React or Vue.js when developing in JavaScript).

But so far we only dealt with functions and static values. To create an _interactive_ user experience we must
be able to _react to_ and _collect_ user input.

To be able to look at a complete app lets consider the following goal.
> The user interface should be a `paragraph` with two elements:
>
> 1. a `text` displaying the current number
> 2. a button to increase the number by one
> 3. a button to lower the number by one

## View

The `view` function is responsable to define the structure of our HTML content.
So lets start with the HTML that complies with the structure as described above:

```elm
view currentNumber = p [] [currentNumberAsText currentNumber, moreButton, lessButton]
```

A paragraph in HTML is represented by the `<p>` element. The `Html` package from Elm gives us access to
the `p` function which creates the element for us.

The `p` function needs two arguments:

1. the list of attributes (we don't need any so we pass in the empty list `[]`)
2. the list of elements that we want to be _inside_ the paragraph.

We made up the names `currentNumberAsText` and `moreButton` and hand those as second argument to the `p` function.
Now let's define them:

```elm
moreButton = button [] [text "more"]
lessButton = button [] [text "less"]
```
The buttons also has no attributes, but we pass in a `text` to have a label on them.

```elm
currentNumberAsText number = text (String.fromInt number)
```

`currentNumberAsText` is a function that **transforms** an `Int` into a HTML text.
To use the `text` function from the HTML we have to convert the `Int` to a `String` **first**.


## `update`

The next function that every Elm app has is the `update` function. 
It describes how every of the possible user interactions affects the current state
(aka number in our case) of the app.

To descrive _every possible_ user interaction every Elm app defines a _custom type_ with a
variant for each interaction.

Our app has two possible interactions:

1. The "more" button was clicked
2. The "less" button was clicked

The type for the interactions is usually called `Msg` and we define it like this for our app:

```elm
type Msg = More | Less
```

Now that we have that type we can define our `update` functions that: 

1. looks at the interaction aka `Msg`
2. takes the last state
3. transforms those two into the next state/number

```elm
update msg currentNumber =
  case msg of
      More -> currentNumber + 1
      Less -> currentNumber - 1
```

Now we just have to wire up our buttons to send the right `Msg` by adding an `onClick` attribute for each:

```elm
moreButton = button [onClick More] [text "more"]
lessButton = button [onClick Less] [text "less"]
```

So far we have never _called_ the `update` or `view` function. And in fact we never have, because Elm will do it for us.
We just have to return our functions wrapped up in a `Browser.sandbox` from the `main` function.
The `init` value is whatever we want our "current number" to be whenever the app/page gets loaded.

```elm
main = Browser.sandbox { view = view, update = update, init = 99 }
```

**Congratulations!** 🎉 I know we had to cover a lot of ground to get here 🥵 but you now know how _every_ Elm app works!
Of course there is still a lot of powerful tools to discover but this basic cycle is always the same.

## Exercise

You definitly deserve a break if you've mad it until here, but if you still want to test your understanding try to add a 
"times ten" button, that when pressed multiplies the current number by ten.

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

