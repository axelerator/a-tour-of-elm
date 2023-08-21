module Lessons.CSSRules exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))
import List exposing (all)


lesson =
    { id = CSSRulesId
    , title = "CSS Rules"
    , body = body
    , lessonFiles = [ indexHtml ]
    }


indexHtml =
    { filename = "index.html"
    , filetype = HtmlFile
    , content = html
    }


body =
    """# CSS rules and selectors
Being able to style our elements one by one is very powerful, but it is also kind of repetetive.
This becomes especially annoying when we have _a lot_ of similar elements that we want to look all
the same.

That's what _CSS rules_ are for. A CSS rule combines two things:

1. a set of properties
2. a `selector` that describes to which elements of the document these properties should be applied

Here is an example: 

```css
h1 {
  color: red;
  text-decoration: underline;
}
``` 

The **selector** is what's in front of the opening bracket `{`. In this
case it's just `h1` which means: > Apply the following properties to _all_
`<h1>` elements in the HTML document.

Selectors can be a lot more complicated to select exactly the elements. For an
in-depth introduction revisit the corresponding section in the
[mdn](https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/Selectors)
or explore them with this [visual guide](https://fffuel.co/css-selectors).

## Adding style

So how do we add those rules to our document. Since the rules themselves don't
have a visual representation (no one wants to read the rules when they read the
document) we put them in the `<head>` element of the HTML document. 

The `<head>` element lives _next_ to the `<body>` that contains the visible
content. Inside the `<head>` element we can place a `<style>` element, and that
is where we finally can place our _CSS rules_.

On the right you see an HTML document with a style section that contains a
single rule to turn all headings purple.

### Exercise

Add another rule that changes the `background-color` of all paragraphs `<p>` to
a [color](https://developer.mozilla.org/en-US/docs/Web/CSS/color) of your
choice. """


html =
    """<html>
  <head>
    <style>
      h1 {
        color: purple;
      }
    </style>
  </head>
  <body>
    <h1>I am a heading!</h1>
    <p>I am a paragraph</p>
    <h1>I also am a heading!</h1>
    <p>I am another paragraph</p>
  </body>
</html>"""
