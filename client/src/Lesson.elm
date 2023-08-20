module Lesson exposing (..)

type alias LessonDescription =
  { id: LessonId
  , lesson : Lesson
  , title : String
  , body : String
  }

type FileType
    = HtmlFile
    | CSSFile
    | ElmFile


type alias LessonFile =
    { filename : String
    , filetype : FileType
    , content : String
    }


type LessonId
    = HtmlIntroId
    | CSSIntroId
    | ElmIntroId


type Lesson
    = HtmlIntro { indexHtml : LessonFile }
    | CSSIntro { indexHtml : LessonFile, stylesCss: LessonFile }
    | ElmIntro { indexHtml : LessonFile }

lessonIdStr : LessonId -> String
lessonIdStr id =
  case id of
      HtmlIntroId -> "HtmlIntro"
      CSSIntroId -> "CSSIntro"
      ElmIntroId -> "ElmIntro"

