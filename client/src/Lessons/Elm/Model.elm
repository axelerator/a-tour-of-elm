module Lessons.Elm.Model exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))
import Debug exposing (todo)


lesson =
    { id = ElmModel
    , title = "The Model"
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
import Html exposing (Html, button, p, text, input)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput)

type alias Model =
  { username: String }

init : Model
init = { username = "guest" }

view : Model -> Html Msg
view model = p [] [usernameInput model.username]

usernameInput : String -> Html Msg
usernameInput username = 
  input [onInput UsernameChanged, value username] []

type Msg = UsernameChanged String

update : Msg -> Model -> Model
update msg model =
  case msg of
    UsernameChanged newUsername -> 
      { username = newUsername }

main = Browser.sandbox 
  { view = view
  , update = update
  , init = init
  }
"""


body =
    """## The _Model_ type

A crucial part plays the _state_ of the application. It's what we called 
`currentNumber` in the previous lesson.

Each of the central building blocks of the Elm app (the `view`, `update` and `init` function) 
work with the the `currentNumber`.

Of course real applications cannot capture their entire state in just a single number. 
In Elm the type for this state is called _the model_.
In _our_ application we can call it whatever we want, but it's customary, and a lot less confusing,
to also just call it `Model`.

The type _alias_ that we define just gives a name to use instead of the _record_ structure that's defined.
It's different from the "non alias" type that it doesn't have the variant.
It's a record of exactly that structure.

```elm
type alias Model =
  { username: String }

init : Model
init = { username = "guest" }
```
When we start the app we want the input to be prefilled with the value `"guest"`, so we crate an `init` value
where the `username` field has the desired value.

Now that we have a _name_ for our model type we can use it to write down what we expect our `view` function
to do by writing down it's signature:

```elm
view : Model -> Html Msg
```

This can be read the following way:

> The `view` function **takes** a value of type `Model` and **returns** `Html`
> (that can generate messages of type `Msg`).

The `view` function mainly relies on the `usernameInput` function.

```elm
view model = p [] [usernameInput model.username]

usernameInput : String -> Html Msg
usernameInput username = 
  input [value username, onInput UsernameChanged] []
```

The `usernameInput` function takes a value `username` and returns an 
[input form element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input).

When we look up the [`input` function in the Elm package documentation](https://package.elm-lang.org/packages/elm/html/latest/Html#input)
we see that it takes two arguments:

1. a list of attributes (`List (Attribute msg)`)
2. a list of children/content 

The `input` doesn't take any child elements so we pass in the empty list `[]` as second argument. 
The _first_ argument is a list of two attributes. The first one is the [value]() attribute.
It makes sure the input shows the current `username` field of our `model`.
The second one is the event handler function `onInput`. It will "send" a message each time the users
types into the input field.

The `onInput` function expects us to tell us which message. It wants to generate a message
that can "carry" the changed input value. 
Our `UsernameChanged String` variant can do exactly that.

```elm
update : Msg -> Model -> Model
update msg model =
  case msg of
      UsernameChanged newUsername -> 
        { username = newUsername }
```

So when the user types into the `input` Elm will call our `update` function with the `UsernameChanged` method.
Pattern matching on that variant the `case` expression will return a brand new `Model` value, where the 
username field now reflects the value the `input` had _after_ the user changed it.

``elm
main = Browser.sandbox 
  { view = view
  , update = update
  , init = init
  }
```

Finally we give pass our three functions to the Elm `sandbox` to have it do all the wiring for us.

### Exercise

1. Add a second input field that lets the user type in a password.
2. Use the `type_` attribute to have the input hide which characters are typed in the password input.


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


