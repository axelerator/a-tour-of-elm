module Lesson exposing (..)


type alias LessonDescription =
    { id : LessonId
    , title : String
    , body : String
    , lessonFiles : List LessonFile
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
    | HtmlAttributesId
    | HtmlUrlAndImagesId
    | CSSIntroId
    | CSSRulesId
    | CSSIncludeId
    | ElmIntroId


type alias Lesson =
    List LessonFile


lessonIdStr : LessonId -> String
lessonIdStr id =
    case id of
        HtmlIntroId ->
            "HtmlIntro"

        CSSIntroId ->
            "CSSIntro"

        CSSRulesId ->
            "CSSRules"

        CSSIncludeId ->
            "CSSInclude"

        ElmIntroId ->
            "ElmIntro"

        HtmlAttributesId ->
            "HtmlAttributesId"

        HtmlUrlAndImagesId ->
            "HtmlAttributesId"
