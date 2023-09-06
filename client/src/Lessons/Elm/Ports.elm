module Lessons.Elm.Ports exposing (lesson)

import Char exposing (toLocaleUpper)
import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmPorts
    , title = "Outgoing Ports"
    , body = body
    , lessonFiles = [ mainElm, indexHtml ]
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
    """# Talking to the outside world with _ports_

We already encountered _Commands_ as pattern to use the browsers inbuilt JavaScript functionality to
make Http requests that "leave" our application.
And the code that gives us commands has been vetted by the Elm team to guarantee we always get the expected
behaviour.

There is however an enormous amount of existing JavaScript functions and libraries that have not been _wrapped_
in custom `Cmd`s and are hence inaccessible to us. Even browsers themselves add new JavaScript functions/APIs at a rate
that's hard for language/framework providers to keep up with.

To still be able to interact with the "outside" JavaScript world Elm offers a concept called **ports**.
Ports build upon the concepts of _Commands_ and _Subscriptions_.

We can call arbitrary JavaScript functions by declaring an _"outgoing"_ port. This port gives us a `Cmd` that
we can use to "fire and forget" a JavaScript function.

There are also _"incoming"_ ports which allows us to **receive** information from the JavaScript world 
by giving us a subscription, which we'll look into in a follow up lesson.

## Motivation

In this lesson we'll use an _outoging_ port to implement the following behaviour:

> When a users logs in we want to _store_ their username.
> This way when they logout we can **prefill** the username input with that name

Modern browser have an inbuilt JavaScript API to store site specific information called 
[`localStorage`](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage).

Data stored here will be available even after the browser has been closed and reopend.

## Adding ports to the Elm side

Elm requires us to mark our `Main` module to contain ports. We have to add the `port` keyword to the
module declaration in the first line.

```elm
port module Main exposing (main)
```
This allows us to declare the actual port as it happens in line `9`:

```elm
port storeLastUser : String -> Cmd msg
```
It looks a lot like a function signature with two differences:

1. It is preceeded with the keyword `port`
2. It is not followed by any function body/implementation

But otherwise it behaves very much like a regular function in our Elm program. That means in our case

> `storeLastUser` is a function <br>
> that **takes** a `String` <br>
> and **returns** a command.

We can use this function in our `update` function. At the time when we receive a positive answer from
the server to our login request we want to use it to store the name of the user that was just logged in.
So instead `Cmd.none` we now return `storeLastUser username` as part of our `(Model, Cmd Msg)` result of
the `update` function.

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- other branches omitted for brevity
    GotLoginResponse username result ->
      case result of
        Ok fullText ->
          ( LoggedIn { response = fullText, secondsUntilLogout = 20 }
          , storeLastUser username
          )
    -- ..
```

We smuggeled in an additional argument to our `GotLoginResponse` message. In the last lesson it only held
the `result` from the request to the login API.
But since we need to know **which** user we logged in, we add a `String` argument to the `GotLoginResponse`
variant.


```elm
type Msg =
  -- other variants omitted
  | GotLoginResponse String (Result Http.Error String)
```

This gives us the opportunity to use an Elm language feature called _"partial application"_.
The `Http.expectString` expects a message that is only missing the `Result`, but our `GotLoginResponse`
expects a `String` **and** a `Result`. We can _"prefill"_ the variant **partially** by already _"attaching"_
the `username` to take up the `String` spot.

Now `Http.expect` is happy again, because it only has to "fill" the `Result` spot again.

```elm
sendLoginRequest : String -> Cmd Msg
sendLoginRequest username =
  Http.get
      { url = "/half_login/" ++ username
      , expect = Http.expectString (GotLoginResponse username)
      }
```

At this point the wiring on the Elm side is complete. Now we have to _"connect"_ the JavaScript part,
which happens in the `index.html`.

## Connecting the port with JavaScript

We haven't looked at the `index.html` so let's quickly recap what happened in those first three lines
in the `<script>` element.

The included `main.js` that contains our compiled Elm app gives us an `Elm.Main` object with an `init`
function.
Calling this function with a `node` replaces this element in the document with our app.
It also **returns** our app as JavaScript object and we store it in a variable called `app`.

```javascript
var app = Elm.Main.init({
  node: document.getElementById('myapp')
});
```

The latter is important because this object contains the JavaScript "outlets" for our ports.
This `app.ports` object of our app contains an object for each port we declared in our app.

For an _outgoing_ port this object has a `subscribe` function. When we call `subscribe` for
our port it expects us to give it _another_ function.
This function (`storeToLocalStorate`) will now be executed **each time** we issue the port command
for that port in our Elm application.


```javascript
app.ports.storeLastUser.subscribe(storeToLocalStorate);
```

The `storeToLocalStorate`(which has to be defined before we call subscribe in the `index.html`) connects
the `data` we received from the port with the [`localStorage.setItem` function](https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem)
of the browser.
Calling `window.localStorage.setItem("lastUser", "Ida")` stores the _value_ `"Ida"` under a new entry called `"lastUser"`.

```javascript
const storeToLocalStorate = (dataFromPort) => {
  window.localStorage.setItem("lastUser", dataFromPort)
}
```


## Recap

1. **outgoing ports** allow us to execute arbitrary JavaScript functions
2. They give us a **command** that we can **return** from our `update` function
3. The Elm code does not actually know **which** JavaScript function will be executed
4. We have to **subscribe** to the matching object in the of our Elm app in the `index.html`

> Attention: **Caveat!**<br>
> If we _never_ actually return the `Cmd` of our port the `app.ports` in our `index.html` will not 
> have an "outlet" for that unused port.

### Exercise

We're not using the stored value yet (we'll look into that in our next lesson). 

But there are two ways to user the browser to find out whether the name was stored.
Both require that you open the 
[_"development tools"_](https://developer.mozilla.org/en-US/docs/Learn/Common_questions/Tools_and_setup/What_are_browser_developer_tools)
of your browser, which works differently for each browser. So if you don't know it search for "how to open development tools"
plus the name of your browser should yield you the necessary instructions.

The first way to verify the username was stored _after_ you hit the "login" button is to use the
[`localStorage.getItem` function](https://developer.mozilla.org/en-US/docs/Web/API/Storage/getItem).

Find the tab that says `console` in your browsers development tools. This will give you a field to input text (usually
with a `>` in the beginning).

Enter `localStorage.getItem('lastUser')` and hit the `enter` key. If the value was persisted successfully this 
should have printed out the name of the logged in user.

The second way which is also a bit different in each browser is to use the development tools to inspect the
local storage directly. The tools have a tab called "Application" or "Storage" that shows all key value pairs.
If you are can't find them search for "Howto inspect local storage" plus your browsers name to find instructions.
  """


elmMainContent =
    """port module Main exposing (main)
import Browser
import Html exposing (Html, text, input, button, p)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput, onClick)
import Http
import Time

port storeLastUser : String -> Cmd msg

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
  | GotLoginResponse String (Result Http.Error String)
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
    GotLoginResponse username result ->
      case result of
        Ok fullText ->
          ( LoggedIn { response = fullText
                     , secondsUntilLogout = 20
                     }
          , storeLastUser username
          )
        Err _ ->
          ( LoggedOut { username = ""
                      , error = "Something went wrong"
                      }
          , Cmd.none
          )
    ASecondLater _ -> 
      case model of
        LoggedIn { response, secondsUntilLogout } ->
          if secondsUntilLogout > 0 then
            ( LoggedIn { response = response
                       , secondsUntilLogout = secondsUntilLogout - 1
                       }
            , Cmd.none
            )
          else
            ( LoggedOut { username = "guest"
                        , error = "You have been logged out due to inactivity"
                        }
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
      , expect = Http.expectString (GotLoginResponse username)
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

    const storeToLocalStorate = (dataFromPort) => {
      window.localStorage.setItem("lastUser", dataFromPort)
    }

    app.ports.storeLastUser.subscribe(storeToLocalStorate);
    </script>
  </body>
</html>"""
