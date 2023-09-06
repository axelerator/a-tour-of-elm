module Lessons.Elm.Commands exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmFirstSteps
    , title = "Http with Commands"
    , body = body
    , lessonFiles = [mainElm, indexHtml]
    }

indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = indexHtmlContent
    }


mainElm =
    { filename = "Main.elm"
    , filetype = ElmFile
    , content = elmMainContent
    }


body =
    """### Making Http calls with commands

So far our applications followed a strict loop:

1. use `init` to set intitial model state
2. use that `model` to generate HTML with `view` function
3. wait for user to generate a _message_ by for example clicking or typing
4. use the `update` function to generate a new state for the model
5. start over at 2.

But not all information flows can be expressed by that pattern. Most notably making an Http request
is one of those things. 

In this lesson we'll extend our login example to make an actual API call. 
That means we'll send a Http request from our app to the webserver. The same we request HTML, CSS and JS
files from. But instead of asking for a file we'll send our _login credentials_ (username and password) 
to let it tell us whether this is a valid login.

## What are commands?

Sending a request to a server and getting a response looks a bit like calling a function, but there are
some crucial differences which is why they are modelled as **Commands**.

One thing that makes Elm applications extremely reliable is that Elm can rely on the fact that a function
will _always_ return the same result for a given set of arguments. Elm can't guarantee that for Http calls
because it is completely up to the server what it responds with.

The other big difference is that Http calls use the network/internet to retrieve the answer.
Waiting for the answer to come back from the server can take seconds, minutes or fail entirely.
If that happens during a "normal" function call our application would just "hang" there, and that's
something we want to avoid at all costs.

Elm uses a pattern called _commands_ to avoid this systematically.

The trick is to split up the operation into two parts:

1. The "do the thing" - in our case send the Http request
2. Specify a _message_ to send **when** we get the result/response

## How to use commands to make an Http request

We are going to make a Http request to our _"half login API"_ for this Lesson.
It's only "half" because you don't need a password. Simply replace `YOUR_NAME` in this URL
[https://a-tour-of-elm.axelerator.de/half_login/YOUR_NAME](/half_login/YOUR_NAME) and open it
in a new browser tab and the server will respond with `Welcome YOUR_NAME`.

To be able to use commands in our Elm application we have to leave the sandbox.
That means instead of calling [`Browser.sandbox`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#sandbox)
we will use [`Browser.element`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#element).

This adds the `subscriptions` field that we'll discuss in the next chapter, but it also has different **signature**
for `init` and `update` functions.

```elm
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = \\_ -> Sub.none
    , view = view
    }
```
Commands are returned as part of the result of the `update` function.
The `update` function we're expected to give to `Browser.element` has a different signature than the
ones we've written so far. The new signature looks like this:

```elm
update : Msg -> Model -> (Model, Cmd Msg)
```
So, as before, it still **takes** a message and a model, but it returns a pair of the updated model
and a command!. 

We added a `button` to our `view` function and a new **variant** for our `Msg` type called `SubmitClicked`.
We use the `onClick` attribute to send that message when the user clicks this button.

This happens also to be the moment we want to make the Http request. So let's look at that case in our `update` 
function:

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- ..
    SubmitClicked -> 
        (model, sendLoginRequest model.username)
    -- ..

```
When our update function _receives_ the `SubmitClicked` message we now return two things!

1. the unaltered model (the user interface stays exactly the same)
2. the **command** to send the Http to the login API

To return them as a pair (also called [Tuple](https://package.elm-lang.org/packages/elm/core/latest/Tuple)) 
we wrap the two values in paranthesis and separate them with a comma.

The `sendLoginRequest` function is what actually gives us the command. From it's signature we can see:
It _takes_ a username and _returns_ a command.

```elm
sendLoginRequest : String -> Cmd Msg
sendLoginRequest username =
  Http.get
      { url = "/half_login/" ++ username
      , expect = Http.expectString GotLoginResponse
      }
```

The `Http.get` function comes from the official [elm/http](https://package.elm-lang.org/packages/elm/http/latest/)
package. 
We give it two things:

1. The URL to call, which is our "half login" API combined with the username from our model
2. A message to _send_ when the server responded

This is why the the type for our command is `Cmd Msg`. It tells Elm that this is a command that will send
a message, and this message is of _our_ msg type called `Msg`.

This pattern is called a **type parameter**. You've maybe noticed it already in the signature of our view
function which returns `Html Msg`. Because our HTML can also "send" messages of type `Msg`.

After our request is sent, the server will (hopefully) _respond_ with the `Welcome...` text.
In that case Elm will call our `update` function with the `GotLoginResponse` message.

You might expect that `Msg` variant to just come with a `String` for the response. But as mentioned eariler
a lot of things can go wrong on the way to the server.
That's why `GotLoginResponse` is declared as follows:

```elm
type Msg 
  -- other variants omitted
  | GotLoginResponse (Result Http.Error String)
```

A `Result` is a type that comes [with Elm](https://package.elm-lang.org/packages/elm/core/latest/Result) and 
is made exactly for situations where something can go wrong. It's defined as follows:

```elm
type Result error value
    = Ok value
    | Err error
```
It has two variants `Ok` and `Err`. But it also has two _type parameters_ 🤯, because in both cases we want
the variants to carry some data!

In our case `Result Http.Error String` that means a result can be one of two variants:

1. `Ok String` - indicating we did a proper response from the server and our value will 
   come with the welcome message
2. `Err Http.Error` which means an error specific to trying to make a Http request ocurred.

Now let's look at the respective branch in our `update` function to learn what we'll do with all that information:

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- .. previous branches omitted
    GotLoginResponse result ->
      case result of
        Ok fullText ->
          ( { model | response = fullText }, Cmd.none)
        Err _ ->
          ( { model | response = "Something went wrong" }, Cmd.none)
```
If we got `GotLoginResponse` we get one of the aforementioned variants so _pattern match_ on each of them.
In the `Ok String` case we give the string argument the name `fullText`. Then we **return** the `(model, command)`
pair we're expected to return from the `update` function.

We use a new piece of syntax we haven't seen before to create the new `model` state:

```elm
{ model | response = fullText }
```
This will create a copy of the old model where everything is exactly the same, but the `response` field will
have whatever value `fullText` has.
It's exactly the same as writing 

```elm
{ username = model.usernameInput
, response = fullText
}
```

But it has two advantages:

1. It's much shorter to write
2. If we later add fields to our `Model` type we don't have to add them here too

## Recap

That was a lot of ground we've covered here. Let's summarize again what has changed from our command-less 
app from the last lesson:

1. We switched from `Browser.sandbox` to `Browser.element`
2. Our `update` function has to return a pair `(Model, Cmd Msg)` now
3. When the user clicks the button we return a command by using `Http.get`
4. When the response arrives from the server we get to handle the `GotLoginResponse` message
5. If the result in that message is `Ok ..` we update the `response` field of our model with the contained string.

### Exercise

The `init` function can also return a pair with a command now! A command returned here will be executed 
immediately when the app starts. Can you send a login request immediately so the app says "Welcome stranger"
without the user typing or clicking anything?
  """

elmMainContent = 
  """module Main exposing (main)
import Browser
import Html exposing (Html, text, input, button, p)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput, onClick)
import Http

type alias Model =
  { username: String
  , response: String
  }

init : () -> (Model, Cmd Msg)
init _ = 
  ( { username = "guest", response = "" }
  , Cmd.none
  )

view : Model -> Html Msg
view model = 
  p [] 
    [ usernameInput model.username
    , p [] [text model.response]
    , button [onClick SubmitClicked] [text "login"]
    ]

usernameInput : String -> Html Msg
usernameInput username = 
  input [onInput UsernameChanged, value username] []

type Msg 
  = UsernameChanged String
  | SubmitClicked
  | GotLoginResponse (Result Http.Error String)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UsernameChanged newUsername -> 
        ( { model | username = newUsername }, Cmd.none)
    SubmitClicked -> 
        (model, sendLoginRequest model.username)
    GotLoginResponse result ->
      case result of
        Ok fullText ->
          ( { model | response = fullText }, Cmd.none)
        Err _ ->
          ( { model | response = "Something went wrong" }, Cmd.none)

sendLoginRequest : String -> Cmd Msg
sendLoginRequest username =
  Http.get
      { url = "/half_login/" ++ username
      , expect = Http.expectString GotLoginResponse
      }

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = \\_ -> Sub.none
    , view = view
    }
  """



indexHtmlContent =
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
