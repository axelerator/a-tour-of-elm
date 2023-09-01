module Lessons.Elm.CustomTypes exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmLang
    , title = "Custom Types & Aliases" 
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

main = text complaint

complaint = "The patient's " ++ discomfort hurtingBodyPart

hurtingBodyPart = Arm Left

type Side = Left | Right
type BodyPart = Leg Side | Arm Side | Head

discomfort : BodyPart -> String
discomfort bodyPart =
  case bodyPart of
    Head -> "head aches"
    Arm Left -> "left arm hurts"
    Arm Right -> "right arm hurts"
    Leg Left -> "left arm hurts"
    Leg Right -> "right arm hurts"
"""


body =
    """## Custom Types

This is the _last_ topic we need to tackle to be able to write our first _interactive_ Elm apps.

Until now we've encountered only types that come out-of-the-box with Elm: `Int`, `String, ...

We've seen how using the proper types helps the Elm compiler help us, for example by making sure
we don't forget to cover certain variants in a pattern matching `case` expression.

Let's say we want to create an app that helps medical professionals to create diagnose.
We want to ask the patient which one of for example their legs hurt. The answer can be either 
"left" or "right".

Now we could store that as `String` but that would force us to always deal with _all other possible `String`s__
as well:

```elm
case sideOfPain of
    "left" -> "Left leg bad"
    "right" -> "Right leg bad"
    _ -> ????
```

To avoid this we can use the `type` keyword to make up our _own type_:

```elm

type Side = Left | Right

legDiscomfort : LegSide -> String
legDiscomfort legPain =
  case sideOfPain of
      Left -> "Left leg bad"
      Right -> "Right leg bad"
```

Values of our new type `Side` can only ever be `Left` or `Right`.
The compiler knows that and is happy that we covered _all_ cases in the above `case` expression.

We can also _attach data_ to the variants. Lets model a more complicated custom type for more body parts
by reusing our `Side` type as data for arms and legs.

```elm
type BodyPart = Leg Side | Arm Side | Head
```
`BodyPart` is a type with three _variants_:

1. The `Leg` variant has _one_ data attibute of type `Side`. That means every times we have a `Leg` it also 
   has to know it's `Side`, which can only be `Left` or `Right`.
2. The same holds for the `Arm` variant
3. The `Head` variant does not have any data attached since we only have one 🙈

We can now write the following function to describe to the doctor what the patient complained about:

```elm
discomfort : BodyPart -> String
discomfort bodyPart =
  case bodyPart of
    Head -> "head aches"
    Arm Left -> "left arm hurts"
    Arm Right -> "right arm hurts"
    Leg Left -> "left arm hurts"
    Leg Right -> "right arm hurts"
```

You can execute the full example on the right to see that the Elm compiler confirms that we handled all body 
that we defined.

### Exercise

Add `BodyPart` variants for heart and feet to the `BodyPart` `type` definition.


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
