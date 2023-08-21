module Lessons.CSSInclude exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = CSSIncludeId
    , title = "External Stylesheets"
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

"""

html = """
"""
