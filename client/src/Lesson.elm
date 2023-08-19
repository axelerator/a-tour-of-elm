module Lesson exposing (..)


type FileType
    = HtmlFile
    | CSSFile


type alias LessonFile =
    { filename : String
    , filetype : FileType
    , content : String
    }


type LessonId
    = HtmlIntroId
    | CSSIntroId


type Lesson
    = HtmlIntro { indexHtml : LessonFile }
    | CSSIntro { indexHtml : LessonFile, stylesCss: LessonFile }

lessonIdStr : LessonId -> String
lessonIdStr id =
  case id of
      HtmlIntroId -> "HtmlIntro"
      CSSIntroId -> "CSSIntro"

lessonId : Lesson -> LessonId
lessonId lesson =
    case lesson of
        HtmlIntro _ ->
            HtmlIntroId
        CSSIntro _ ->
            CSSIntroId


lessonTitle : Lesson -> String
lessonTitle lesson =
    case lesson of
        HtmlIntro _ ->
            "Hello HTML"
        CSSIntro _ ->
            "Hello CSS"




