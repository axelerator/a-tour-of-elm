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
    | JSFile
    | ElmFile


type alias LessonFile =
    { filename : String
    , filetype : FileType
    , content : String
    }


type LessonId
    = WelcomeId
    | HtmlId
    | SPAId
    | HtmlIntroId
    | HtmlAttributesId
    | HtmlUrlAndImagesId
    | CSSId
    | CSSIntroId
    | CSSRulesId
    | CSSIncludeId
    | JSId
    | JSIntroId
    | JSFunctionsId
    | ElmId
    | ElmIntroId
    | ElmLang
    | ElmTEA
    | ElmLoginFrom
    | ElmPatternMatching
    | ElmFirstSteps
    | ElmModel
    | ElmCommands
    | ElmSubscriptions
    | ElmPorts


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

        JSIntroId ->
            "JSIntro"

        JSFunctionsId ->
            "JSFunctions"

        ElmIntroId ->
            "ElmIntro"

        HtmlAttributesId ->
            "HtmlAttributesId"

        HtmlUrlAndImagesId ->
            "HtmlUrlAndImagesId"

        WelcomeId ->
            "WelcomeId"

        SPAId ->
            "SPAId"

        HtmlId ->
            "HtmlId"

        CSSId ->
            "CSSId"

        JSId ->
            "JSId"

        ElmId ->
            "ElmId"

        ElmLang ->
            "ElmLang"

        ElmLoginFrom ->
            "ElmLoginFrom"

        ElmTEA ->
            "ElmTEA"

        ElmPatternMatching ->
            "ElmPatternMatching"

        ElmFirstSteps ->
            "ElmFirstSteps"

        ElmModel ->
            "ElmModel"

        ElmCommands ->
            "ElmCommands"

        ElmSubscriptions ->
            "ElmSubscriptions"

        ElmPorts ->
            "ElmPorts"
