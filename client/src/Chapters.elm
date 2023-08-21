module Chapters exposing (..)

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

We're here to guide you every step of the way. 
Each chapter is packed with hands-on examples that you can run, experiment 
with, and build upon. Ever wondered how those snappy web apps work behind the 
scenes? Elm's got the answers, and we're here to help you unlock its magic.

So, let's dive in, have fun, and explore the amazing possibilities of web development with Elm.
"""
    }


htmlChapterContent : ChapterContent
htmlChapterContent =
    { title = "What is HTML?"
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
    { title = "What is CSS?"
    , body = "Hi there!"
    }


elmChapterContent : ChapterContent
elmChapterContent =
    { title = "What is Elm?"
    , body = "Hi there!"
    }

