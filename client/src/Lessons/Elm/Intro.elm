module Lessons.Elm.Intro exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmIntroId
    , title = "Intro to Elm"
    , body = body
    , lessonFiles = []
    }


body =
    """### Single Page Applications with Elm

On the [official Elm homepage](https://elm-lang.org) Elm is described as 

> A delightful language for reliable web applications.

But there are a few non-obvious things to unpack in that sentence that need us to understand _what kind_ of web apps we're talking.
Elm applications are _"Single Page Applications"_(SPA). Traditional websites achieve interactivity by sending
you from one page to another.

With SPAs you stay on the same page/HTML document. Interactivity is achieved by **modifying** the HTML(DOM) of
that very page.

Other popular technologies to create SPAs are [React](https://react.dev), [Vue.js](https://vuejs.org), 
[Angular.js](https://angularjs.org) which are all JavaScript _frameworks_.

That means you write your application code in JavaScript. These frameworks themselves are _also_ written in JavaScript
and you have to include their code as part of you application.

To get the framework's code and bundle it up with the app code developers use extra programs called "package managers" or "build tools"
(for example [npm](https://www.npmjs.com) or [yarn](https://yarnpkg.com)).

So when you want to start a JavaScript SPA you have to learn:

- JavaScript
- a framework
- a package manager/build tool

Elm comes with all these things build in. 

That means once you have [installed](https://guide.elm-lang.org/install/elm) you're ready to go!

All the exercises and examples can be copied to your computer and will work out of the box.
  """
