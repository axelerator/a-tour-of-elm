module Lessons.HtmlUrlAndImages exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = HtmlUrlAndImagesId
    , title = "URLs and images"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }


body =
    """# URLs and images

A website without images looks pretty dull. So we're going to learn about the
next super power of the browser which is to pull in **external** content 
**referenced** from your document.

That means an image displayed as part of your document. The image is it's _own_
files and we use a **`URL`** (Uniform Resource Locator) to tell the browser
where it can retrieve that file.

Here is an example of an `URL` that points to an image in the official Elm
guide. If you copy it into the address bar of a new tab of your browser, it
will recognize that it's an image and display it to you.

``` 
https://guide.elm-lang.org/architecture/buttons.svg 
```

On the right you find a document that only contains an `<img />` element. It's
also a _self-closing_ element as it can't contain other elements.

In the `src` attribute we specify the `URL` from where to load the image. 
The alt tag is a mandatory attribute to give a textual description of the images
content for visually impaired people who use screen readers.

Also note how a the attributes can be spread across multiple lines to increase readability.

### Exercise

1. Goto [catoftheday.com](https://catoftheday.com) and right click one of the images. 
2. In the menu that pops up look for _"Copy Image address"_ or _"Copy Image URL"._
3. Update the `src` attribute of the `<img>` element on the right to display that image after you hit run.
    """


html =
    """<html lang="en">
  <head>
    <title>My document</title>
  </head>
  <body>
    <img 
      src="https://guide.elm-lang.org/architecture/buttons.svg" 
      alt="A diagram of the Elm architecture">
  </body>
</html>"""
