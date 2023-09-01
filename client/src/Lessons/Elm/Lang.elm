module Lessons.Elm.Lang exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmLang
    , title = "Values & Functions"
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

greeting = greeter planet

planet = { name = "Earth", circumference = 40075 }

greeter p = "Hello from " ++ planet.name ++ "!"

person = 
  { firstName = "Grace"
  , lastName = "Hopper"
  }
"""


body =
    """## Values and Functions

The syntax of a programming language are the words (aka _keywords_) the language is made of an how you are allowed to combine them.
Due to its focus Elm gets aways with 
[_a lot_ less keywords](https://stackoverflow.com/questions/4980766/reserved-keywords-count-by-programming-language) than other languages.

Every Elm program is build of small building blocks that are easy to pick up. Let's go through a few basics.

## Values

Similar to JavaScript you can give _names_ to values. 

- `myName = "Ada" ` will replace `myName` wherever you use it in your program with `Ada`
- `pi = 3.14` giving names like `pi` to a number makes your program also easier to read over having abstract values everywhere
- `vesuviusEruptedInYears = [172, 203, 222, 303, 379, 472, 512, 536, 685, 787, 860, 900, 968, 991, 999, 1006, 1037, 1049, 1073, 1139, 1150, 1270, 1347, 1500]` 
  Comma separated values, surrounded by square brackets denote a list

## Functions

A function lets us give a name to an operation that _transforms_ one (or multiple) values into another.
For example this creates a function called `doubler`.

```elm
doubler x = 2 * x
```

On the left of the `=` sign is how we want to call the function and how we want to call it's inputs (aka _arguments_). On the 
right of the `=` sign we describe _how_ we transform the _input paramters_ into the output value.

To call a function you just write its name followed by the values that you want to transform, for example:

```elm
answer = doubler 21
```

will compute the number `42` and assign it to the name `answer`.

## Records

For values that belong together we can create a _Record_ with multiple _fields_. Each _field_ has a _name_ and a _value_. 

```elm
planet = { name = "Earth", circumference = 40075 }
```

This creates a creates a record with two _fields_: `name` and `circumference`.
Whenever we use `planet` in our program it will now be replaced by that record.
We can use a `.` + a field name to access to one of it's fields

```elm
nameOfOurPlanet = planet.name
```
Usage of `nameOfOurPlanet` will now always contain `Earth`.

## Exercise

To combine _text values_ (aka `String`s) we can use the `++` operator. You can see how it's used in the example on the right.

Modify the `greeter` function so it says "Hello Grace Hopper from planet Earth!" but uses whatever name is stored in the `person` Record. 
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

