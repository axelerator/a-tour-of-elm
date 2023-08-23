module Lessons.Elm.Types exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))
import List exposing (all)


lesson =
    { id = ElmLang
    , title = "Types"
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
import Html exposing (..)

main = text veryVeryHappy

veryVeryHappy = howHappy 2

howHappy howMuch = iFeelVery howMuch "happy" 

iFeelVery : Int -> String -> String
iFeelVery howMuch how = 
  "I feel " ++ String.repeat howMuch "very " ++ how 
"""


body =
    """## Types

Elm is a _strictly_ typed language. That means it wants to know the exact type of _each_ value when it **compiles** your app.
JavaScript in contrast has to _execute_ your app to find out what type a certain value in your program has at any given time.

But what are _Types_?

Values have the same _type_ when they can be used interchangeably. For example all texts between double quotes (`"Carlos"`,
`"Melon"`, `"Duck"`, `" "`) are of the type called `String`. 

All whole numbers (`4`, `8`, `1500`, `-16`, `23`, `42`) are of the type `Int` (short for "Integer").

Math for real numbers, for example `3.14159`, works differntly for that for whole numbers. So their values can't be used interchangeably
and they have their own type called `Float`.

### Type annotations

The Elm compiler is pretty good at finding out the types of your values ("has quotes" -> String, "number with a decimal point" -> `Float` etc).

Each function has an exact understanding of what _type_ of values it accepts.
As we build up our program by combining values and functions into bigger values and functions we will eventually make mistakes.
In that case the Elm compiler will tell us where we break it's expectations.

Elm let's us write what type _we think_ each value _should have_. This makes our communication with the Elm compiler even more effective.

Writing down what we _think_ the type should be is called writing the the **type signature**. Both functions and values can have type signatures.
The signature goes on top of the actual function/value and has the following format: `NAME_OF_VALUE : TYPE_OF_VALUE`

So for example:

```elm
physisist : String
physisist = "Chien-Shiung Wu"
```

This tells the compiler: 

> I think the value `physist` should be a `String`

For functions the have to name:

- the type of _each_ argument
- the type of the **result**, so the type of the value the arguments get transformed _into_


```elm
iFeelVery : Int -> String -> String
iFeelVery howMuch how = "I feel " ++ String.repeat howMuch "very " ++ how 
```

This tells the compiler: 

> `iFeelVery` is a function that transforms one `Int` and one `String` **into** a `String`.

## Exercise

Add type signatures for `veryVeryHappy` and `howHappy` with the types you think they should have.
If you get it wrong and hit run the compiler error messages will contain helpful information.

Check out the [documentation for `String`](https://package.elm-lang.org/packages/elm/core/latest/String)
to find other interesting functions that can be used with `Strings`.
  """


htmlIntroIndexHtml =
    """<!DOCTYPE html>
<html>
  <head>
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
