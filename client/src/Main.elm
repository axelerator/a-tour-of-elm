port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, li, text, textarea, ul)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)
import Lesson exposing (FileType(..), Lesson(..), LessonFile, LessonId(..), lessonId, lessonIdStr, lessonTitle)
import Lessons.HtmlIntro as HtmlIntro
import Lessons.CSSIntro as CSSIntro


port store : ( String, String, String ) -> Cmd msg


port restore : ( String, Int ) -> Cmd msg


port restored : (List String -> msg) -> Sub msg


lessons : List Lesson
lessons =
    [ HtmlIntro.lesson
    , CSSIntro.lesson
    ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { currentLesson : Maybe Lesson
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentLesson = Nothing }
    , Cmd.none
    )


type Msg
    = GotoLesson LessonId
    | ChangeEditor Int String
    | GotRestoredContent (List String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.currentLesson ) of
        ( GotoLesson id, _ ) ->
            let
                currentLesson =
                    case id of
                        HtmlIntroId ->
                            HtmlIntro.lesson
                        CSSIntroId ->
                            CSSIntro.lesson
            in
            ( { model | currentLesson = Just currentLesson }
            , restore ( lessonIdStr <| lessonId currentLesson, List.length <| lessonEditors currentLesson )
            )

        ( ChangeEditor pos value, Just lesson ) ->
            ( { model | currentLesson = Just <| updateEditor lesson pos value }
            , store ( (lessonIdStr << lessonId) lesson, String.fromInt pos, value )
            )

        ( GotRestoredContent contents, Just lesson ) ->
            let
                indexedContents =
                    List.indexedMap (\i c -> ( i, c )) contents

                f ( pos, value ) l =
                    updateEditor l pos value

                restoredEditors =
                    List.foldr f lesson indexedContents
            in
            ( { model | currentLesson = Just <| restoredEditors }
            , Cmd.none
            )

        _ ->
            ( model
            , Cmd.none
            )


updateEditor : Lesson -> Int -> String -> Lesson
updateEditor lesson pos value =
    let
        updateFile i file =
            if i == pos && value /= "NOT YET STORED" then
                { file | content = value }

            else
                file

        updatedFiles =
            List.indexedMap updateFile <| lessonFiles lesson
    in
    updateLessonEditors updatedFiles lesson


updateLessonEditors : List LessonFile -> Lesson -> Lesson
updateLessonEditors files lesson =
    case (lesson, files) of
        (HtmlIntro lesson_, [indexHtml] )->
            HtmlIntro { lesson_ | indexHtml = indexHtml }
        (CSSIntro lesson_, [indexHtml, stylesCss]) ->
            CSSIntro { lesson_ | indexHtml = indexHtml, stylesCss = stylesCss }
        _ -> lesson


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.currentLesson of
        Just _ ->
            restored GotRestoredContent

        Nothing ->
            Sub.none


view : Model -> Html Msg
view model =
    div []
        [ ul [] <| List.map lessonItemView lessons
        , case model.currentLesson of
            Just lesson ->
                lessonView lesson

            Nothing ->
                text ""
        ]


lessonView : Lesson -> Html Msg
lessonView lesson =
    div [] <|
        (text <| lessonTitle lesson)
            :: lessonEditors lesson


lessonFiles : Lesson -> List LessonFile
lessonFiles lesson =
    case lesson of
        HtmlIntro { indexHtml } ->
            [ indexHtml ]
        CSSIntro { indexHtml, stylesCss } ->
            [ indexHtml, stylesCss ]


lessonEditors lesson =
    List.indexedMap fileView <| lessonFiles lesson


fileView pos { filename, content } =
    div []
        [ text filename
        , textarea [ class "editor", value content, onInput <| ChangeEditor pos ] []
        ]


lessonItemView : Lesson -> Html Msg
lessonItemView lesson =
    li [ onClick <| GotoLesson <| lessonId lesson ] [ text <| lessonTitle lesson ]
