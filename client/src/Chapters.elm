module Chapters exposing (..)
{-

  - Welcome
    - HTML
      - Tags & Elements
      - Attributes
      - URLs & Images
    - CSS
      - Inline styles
      - Rules & Selectors
      - External Stylesheets
    - JavaScript
      - Variables and Statements
      - Functions
      - Interactivity
    - Elm
      - Hello world
      - values & functions
      - Data & Presentation (model + view , just a local model variable with a static value)
      - Interactivity ( color slider)
-}

type alias ChapterContent =
    { title : String
    , body : String
    }

welcome : ChapterContent
welcome =
    { title = "Welcome"
    , body = """# Hi there 👋

Get ready to embark on an exciting journey from zero to creating your own 
interactive single-page web application using Elm.
This tutorial is your gateway to the world of programming,
and guess what? No prior experience required!

Web apps get delivered to the user through the _browser_ utilizing multiple technologies.
Most importantly `Html`, `JavaScript` and `CSS`.

There are already tons of excellent tutorials out there to learn these in depth. And developers spend
years on mastering _each_ of those!

The chapters in this tour aim to provide you ramp you up as quickly as possible, focussing only on what's
absolutely necesseray to be able to put your Elm code into action.

If you're already familiar with them feel free to skip to the Elm chapter directly.
"""
    }


htmlChapterContent : ChapterContent
htmlChapterContent =
    { title = "Intro to HTML"
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
    }


cssChapterContent : ChapterContent
cssChapterContent =
    { title = "Intro to CSS"
    , body = """CSS stands for _Cascading Style Sheets_. 

But all you really have to remember is the _Style_ that it'll bring to your documents.
Where `HTML` is all about **what** is displayed `CSS` allows you to customize **how** it's displayed.

Similar to HTML it's not a _full_ programming language because it too can't _do_ things. It's a way
of expressing a list rules about how to display certain elements of your document.
"""
    }


elmChapterContent : ChapterContent
elmChapterContent =
    { title = "What is Elm?"
    , body = "Hi there!"
    }

