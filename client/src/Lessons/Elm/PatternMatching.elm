module Lessons.Elm.PatternMatching exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))
import List exposing (foldr)


lesson =
    { id = ElmPatternMatching
    , title = "if..then and Pattern Matching"
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

main = text greeting

greeting = "You have " ++ simpleAnswer myFruits

myFruits = ["Apple", "Pear", "Cherry"]

simpleAnswer : List String -> String
simpleAnswer fruits =
  if List.length fruits > 0 then
    "some fruits"
  else
    "no fruits"

betterAnswer : List String -> String
betterAnswer fruits =
  case List.length fruits of
      0 -> "no fruits"
      1 -> "a fruit"
      _ -> "some fruits"

specificAnswer : List String -> String
specificAnswer fruits =
  case fruits of
      [] -> "no fruits"
      ["Apple"] -> "an apple"
      ["Pear"] -> "a pear"
      [_] -> "a fruit"
      _ -> "some fruits"

"""


body =
    """## `If, then, else` and Pattern Matching 

Most of our _functions_ will not be pure mathematical calculations. Depending on what our
app is supposed to do we want to make explicit decisions what the transformed result for
a function should be.

## Meet `if .. then .. else`

The simplest way is the `if` expression, nearly every programming language has a variant of these keywords.

Lets say we want to create a function that _takes_ a list of fruit names and transforms them into a textual summary.

```elm
simpleAnswer : List String -> String
simpleAnswer fruits =
  if List.length fruits > 0 then
    "some fruits"
  else
    "no fruits"
```

The `if` looks at the condition until the `then`, in this case whether the length of the `fruits` list is greater than zero.
If that condition is holds the function will return whatever is between `then` and `else`.
If the list length is greater than zero it will return what's following the `else` keyword.

### `case` .. `of`

Not all descisions in life are black and white. And the same holds in programming.
For those cases we have the `case` expression.

Lets go through the `case` expression from the `betterAnswer` function on the right:

```elm
case List.length fruits of
    0 -> "no fruits"
    1 -> "a fruit"
    _ -> "some fruits"
```

Between `case` and `of` is the expression we want to base our "descision" on.
It is again the "length of the list of fruits". 
But now we can have **more than two** variants of outcomes.

Each variant specifies 
  - "in which case"
  - followed by an arrow "->"
  - followed by what should be returned in that case

Elm makes sure we handle _all possible variants_. So apart from `0` and `1` there
are obvioulsy a lot more other number of fruits one can have.

That's what the `_ -> ..` pattern handles. It basically says:

> if none of the other variants match return the following.

But the pattern syntax of Elm is even more powerful. We can be very specific what to match on.

We can match "on" an exact list like `["Apple"]` in the definition of `specificAnswer`!
The underscore `_` can also be used in a specific pattern.

`[_] -> "a fruit"` means we match on _any_ list that has a single fruit, but we just don't care _what_ fruit.

## Exercise

Add a branch so that when `specificAnswer` is called with `["Coconut", "Pineapple"]` 
it repsonds with "the starting point for a Piña Colada".

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
