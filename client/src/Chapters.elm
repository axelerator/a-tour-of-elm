module Chapters exposing (..)

import Lesson exposing (LessonDescription, LessonId(..))

welcome : LessonDescription
welcome =
    { id = WelcomeId
    , title = "Welcome"
    , body = """# Hi there 👋

Get ready to embark on an exciting journey from zero to creating your own 
interactive single-page web application using Elm.
This tutorial is your gateway to the world of programming,
and guess what? No prior experience required!

Web apps get delivered to the user through the _browser_ utilizing multiple technologies.
Most importantly `Html`, `JavaScript` and `CSS` which is why we cover the basics of those here too.

There are already tons of excellent tutorials out there to learn these in depth. And developers spend
years on mastering _each_ of those! 🥵

The chapters in this tour aim to provide you ramp you up as quickly as possible, focussing only on what's
absolutely necesseray to be able to put your Elm code into action.

Each lesson comes with code examples and a little exercise that you can run in your browser, no software installation needed.

If you're already familiar with them feel free to skip directly to the Elm chapter. 🚀
"""
    , lessonFiles = []
    }


html : LessonDescription
html =
    { id = HtmlId
    , title = "Intro to HTML"
    , body = """
Welcome to Chapter 1, where we dive into the essentials of displaying content
through HTML. 

Here's the key takeaway: web browsers are designed primarily to
showcase documents. 

Their special knack? Fetching these documents from remote
servers. 

Now, what's inside these documents? Well, they're written in a unique
language called HTML. 

HTML uses **tags** – special markers – to outline
content structure. However, HTML isn't concerned with
presentation; it's all about organizing the content's framework. 

HTML is not a _"real"_ programming lanugage because it can't **"do"** things.
For example you can't use HTML to calculate things.

In the upcoming lessons we're going to learn the basics of how to write a HTML document by hand
so the browser is able to display it.
"""
    , lessonFiles = []
    }

spa : LessonDescription
spa =
    { id = SPAId
    , title = "Single Page Applications"
    , body = """
"""
    , lessonFiles = []
    }


css : LessonDescription
css =
    { id = CSSId
    , title = "Intro to CSS"
    , body = """CSS stands for _Cascading Style Sheets_. 

But all you really have to remember is the _Style_ that it'll bring to your documents.
Where `HTML` is all about **what** is displayed `CSS` allows you to customize **how** it's displayed.

Similar to HTML it's not a _full_ programming language because it too can't _do_ things. It's a way
of expressing a list rules about how to display certain elements of your document.
"""
    , lessonFiles = []
    }


js : LessonDescription
js =
    { id = JSId
    , title = "Intro to JavaScript"
    , body = """While `HTML` and `CSS` only described what we want the browser to display JavaScript can be used
to tell the browser **what to do**. Specifically we can use it to user various data sources (user input or APIs) to
**modify** the document we're currently looking at!

That's what makes it a full programming language! Mastering JavaScript takes a long time and comes with a lot of pitfalls.
It is nearly 30 years old! 

A lot of convenience has been added over the years, but because browsers still have to be able to run JavaScript has to 
continue to support some constructs that are very hard to master.

This is where Elm steps onto the stage! The way we write Elm is completely different from JavaScript. However to be able
to run our Elm programs in the browser we need to "translate" them to JavaScript. Luckily the main tool in 
elm development - the _Elm compiler_ - does this (and more) for us.

But since we're _replacing_ the JavaScript part of our technology stack it's good to understand some very minimal basics
of how JavaScript interacts with the HTML in our browser.
"""
    , lessonFiles = []
    }

