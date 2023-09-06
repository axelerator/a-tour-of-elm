module Lessons.Elm.Subscriptions exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmSubscriptions
    , title = "Subscriptions"
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
    """# Listening for events with Subscriptions

To build the case for understanding _"subscriptions"_ we want to add the following feature that you might recognize from your
online bankine: If the **logged in** user is inactive for a given period of time we automatically log them out.

We'll first refactor our `Model` type to explicitly distinguish between a user being logged in or logged out.
With these changes in place the purpose of the subscription pattern will be easier to demonstrate.


## Refactoring the `Model` for explicit states

The new `Model` has two variants representing the two mutually exclusive states the app can be in.
Each variant has a **record** it brings with it.

1. The user is **not** logged in. In this state we want to hold what has been typed into the input field and a potential
   error to display (from a previous login attempt).
2. The user **is** logged in. In this state we want to hold the message we received from the login API request as
   well as the **number of seconds left until the user will be logged out**.

```elm
type Model
  = LoggedOut { username: String, error: String }
  | LoggedIn { response: String, secondsUntilLogout: Int }
```

This means we have to adapt the existing functions that have a `Model` in their signature as well.
The `init` function declares now that the initial state of the `Model` will be the `LoggedOut` variant.
The _default_ for the `username` field continues to be `"guest"` and we add an empty `String` for the error.

```elm
init : () -> (Model, Cmd Msg)
init _ = 
  ( LoggedOut { username = "guest", error = "" }
  , Cmd.none
  )
```

Since our views start to grow, but into significantly different directions it only makes sense to split them up.
We can use the syntax with the curly braces in the "match expression" of our `case` expression to _"grab"_ the 
individual fields by their names out of the records and pass them to the "specialized" view functions (`loggedOutView`,
`loggedInView`).
Leaving each of them with only to deal with what's actually present in the repsective state.

```elm
view : Model -> Html Msg
view model = 
  case model of
    LoggedOut { username, error } ->
      loggedOutView username error
    LoggedIn { response, secondsUntilLogout } ->
      loggedInView response secondsUntilLogout

loggedInView : String -> Int -> Html Msg
loggedInView response seconds = ...

loggedOutView : String -> String -> Html Msg
loggedInView username response = ...
```

The `update` function has to be explicit about the new variants now as well.
Additionally to storing a successful response from the server we want to:

1. Return the `LoggedIn` variant
2. Set the `secondsUntilLogout` to the desired maximum time until the user will be logged out

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- other branches omitted for brevity
    GotLoginResponse result ->
      case result of
        Ok fullText ->
          ( LoggedIn { response = fullText, secondsUntilLogout = 20 }
          , Cmd.none
          )
        Err _ ->
          ( LoggedOut { username = "", error = "Something went wrong" }
          , Cmd.none
          )
```

## Introducing subscriptions

We already established that the user has **20** seconds left before she will logged out.
Now we want to **decrease** this `secondsUntilLogout` field every second! This is where _subscriptions_ come
into play.
We can't rely on the user to interact and/or send a command. So we need this new mechanism.
Instead of just passing `Sub.none` to the `Browser.element` we now delegate that field to a new function
we also just call `subscriptions`.


```elm
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

```

In the new function we use the [`Time.every` function](https://package.elm-lang.org/packages/elm/time/latest/Time#every)
from the [`elm/time` package](https://package.elm-lang.org/packages/elm/time/1.0.0/)
It has the following signature `every : Float -> (Posix -> msg) -> Sub msg`

That means it takes two parametres:

1. A `Float` specifying in milliseconds "how often" we want the event to occur
2. A _message_ (that can "hold" a `Posix`) that's to be send when that event occurrs

But the most interesting part is that it gives us a subscription (`Sub msg`)!


So _our_ `subscriptions` function **takes** the _current_ model and **returns** a `Sub` that can send messages
of our `Msg` type.

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
  case model of
    LoggedOut _ -> Sub.none
    LoggedIn _ -> Time.every 1000 ASecondLater
```

And now we can make use of the fact that we have two **distinct** variants of our `Model`.
Because when the user is not logged in we don't want anything to fire every second. 
Only in the case that the user is **`LoggedIn`** we want: `every` 1000 milliseconds the `ASecondLater` message
to be sent.

Of course the `ASecondLater` variant has to be added to our `Msg` type as well. The `every` function can't guarantee
that the event fires **exactly** at 1000ms so it also passes the _exact time_ with the `ASecondLater` message (as 
a `Posix`). But since _approximately_ a second is good enough for our use case we can just ignore that value (hence
the underscore in the match expression).

To get the "current" `secondsUntilLogout` we pattern match on our model as well.
We grab the `secondsUntilLogout` from the `LoggedIn` variant using the `{..}` syntax and return **a new**
`LoggedIn` state with the `secondsUntilLogout` diminished by `1` second.

```elm
type Msg =
  -- other variants omitted
  | ASecondLater Time.Posix

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- other branches omitted
    ASecondLater _ -> 
      case model of
        LoggedIn { response, secondsUntilLogout } ->
          ( LoggedIn { response = response, secondsUntilLogout = secondsUntilLogout - 1 }
          , Cmd.none
          )
        _ -> 
          ( model
          , Cmd.none
          )
```

## Recap

1. Subscriptions let us _"listen to"_ or _"register"_ functions that will generate events that are triggered from
   "outside" our app/`view`.
2. We can decide based on our `model` what events we want to listen to.
3. Each event is "translated" into a message of our `Msg` type
4. We react to the event by updating our `model` in the `update` function in the branch for that message.

### Exercise

1. Actually log out the user when the `secondsUntilLogout` reach zero. The user should see the input and 
   login button again.
2. There is already a "I'm still here" button in the `loggedInView` that does nothing when clicked.
   Add the behaviour that when the user presses it, it gives them another 20 seconds before they get logged out.

  """

elmMainContent = 
  """module Main exposing (main)
import Browser
import Html exposing (Html, text, input, button, p)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput, onClick)
import Http
import Time

type Model
  = LoggedOut { username: String, error: String }
  | LoggedIn { response: String, secondsUntilLogout: Int }

init : () -> (Model, Cmd Msg)
init _ = 
  ( LoggedOut { username = "guest", error = "" }
  , Cmd.none
  )

view : Model -> Html Msg
view model = 
  case model of
    LoggedOut { username, error } ->
      loggedOutView username error
    LoggedIn { response, secondsUntilLogout } ->
      loggedInView response secondsUntilLogout

loggedInView : String -> Int -> Html Msg
loggedInView response seconds =
    p [] 
      [ p [] [text response]
      , p [] [ text "seconds until logout: "
              , text (String.fromInt seconds)
             ]
      , button [] [text "I'm still here"]
      ]

loggedOutView : String -> String -> Html Msg
loggedOutView username error =
  p [] 
    [ usernameInput username
    , p [] [text error]
    , button [onClick SubmitClicked] [text "login"]
    ]

usernameInput : String -> Html Msg
usernameInput username = 
  input [onInput UsernameChanged, value username] []

type Msg 
  = UsernameChanged String
  | SubmitClicked
  | GotLoginResponse (Result Http.Error String)
  | ASecondLater Time.Posix

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UsernameChanged newUsername -> 
        ( LoggedOut { username = newUsername, error = "" }
        , Cmd.none
        )
    SubmitClicked -> 
      case model of
        LoggedOut { username } ->
          ( model
          , sendLoginRequest username
          )
        _ -> 
          ( model
          , Cmd.none
          )
    GotLoginResponse result ->
      case result of
        Ok fullText ->
          ( LoggedIn { response = fullText, secondsUntilLogout = 20 }
          , Cmd.none
          )
        Err _ ->
          ( LoggedOut { username = "", error = "Something went wrong" }
          , Cmd.none
          )
    ASecondLater _ -> 
      case model of
        LoggedIn { response, secondsUntilLogout } ->
          ( LoggedIn { response = response, secondsUntilLogout = secondsUntilLogout - 1 }
          , Cmd.none
          )
        _ -> 
          ( model
          , Cmd.none
          )

sendLoginRequest : String -> Cmd Msg
sendLoginRequest username =
  Http.get
      { url = "/half_login/" ++ username
      , expect = Http.expectString GotLoginResponse
      }

subscriptions : Model -> Sub Msg
subscriptions model =
  case model of
    LoggedOut _ -> Sub.none
    LoggedIn _ -> Time.every 1000 ASecondLater

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
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
