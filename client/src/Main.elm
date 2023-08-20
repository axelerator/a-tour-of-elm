port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Html exposing (Html, button, div, iframe, input, label, li, text, textarea, ul)
import Html.Attributes exposing (class, for, id, name, src, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Lesson exposing (FileType(..), Lesson(..), LessonFile, LessonId(..), lessonId, lessonIdStr, lessonTitle)
import Lessons.CSSIntro as CSSIntro
import Lessons.HtmlIntro as HtmlIntro
import String exposing (fromInt)
import Task
import Html.Attributes exposing (style)


port store : ( String, String, String ) -> Cmd msg


port restore : ( String, Int ) -> Cmd msg


port restored : (List String -> msg) -> Sub msg


port run : List ( String, String ) -> Cmd msg


port readyForPreview : (String -> msg) -> Sub msg


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


type PreviewState
    = NoPreview
    | Loading
    | Loaded String


type alias Model =
    { currentLesson : Maybe Lesson
    , previewState : PreviewState
    , viewPort : Maybe Browser.Dom.Viewport
    , lessonWidth : Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentLesson = Nothing
      , previewState = NoPreview
      , viewPort = Nothing
      , lessonWidth = 100
      }
    , Task.perform GotViewPort getViewport
    )


type Msg
    = GotoLesson LessonId
    | ChangeEditor Int String
    | GotRestoredContent (List String)
    | ShowPreview String
    | RunCurrentLesson
    | GotViewPort Browser.Dom.Viewport


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.currentLesson ) of
        ( GotViewPort vp, _ ) ->
          ( { model | viewPort = Just vp }
          , Cmd.none
          )
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

        ( RunCurrentLesson, Just lesson ) ->
            ( { model | previewState = Loading }
            , run <| filesForRunning lesson
            )

        ( ChangeEditor pos value, Just lesson ) ->
            ( { model | currentLesson = Just <| updateEditor lesson pos value }
            , store ( (lessonIdStr << lessonId) lesson, String.fromInt pos, value )
            )

        ( ShowPreview hash, _ ) ->
            ( { model | previewState = Loaded hash }
            , Cmd.none
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


filesForRunning : Lesson -> List ( String, String )
filesForRunning lesson =
    List.map (\{ filename, content } -> ( filename, content )) <| lessonFiles lesson


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
    case ( lesson, files ) of
        ( HtmlIntro lesson_, [ indexHtml ] ) ->
            HtmlIntro { lesson_ | indexHtml = indexHtml }

        ( CSSIntro lesson_, [ indexHtml, stylesCss ] ) ->
            CSSIntro { lesson_ | indexHtml = indexHtml, stylesCss = stylesCss }

        _ ->
            lesson


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.currentLesson of
        Just _ ->
            case model.previewState of
                Loading ->
                    readyForPreview ShowPreview

                _ ->
                    restored GotRestoredContent

        Nothing ->
            Sub.none


view : Model -> Html Msg
view model =
    div []
        [ ul [] <| List.map lessonItemView lessons
        , case model.currentLesson of
            Just lesson ->
                lessonView model.lessonWidth lesson model.previewState

            Nothing ->
                text ""
        ]

px : Int -> String
px x = (fromInt x) ++ "px"

lessonView : Int -> Lesson -> PreviewState -> Html Msg
lessonView lessonWidth lesson previewState =
    div [ class "lessonContainer" ]
        [ div [ class "separator", style "left" (px lessonWidth)  ] []
        , div [ class "left", style "width" (px lessonWidth) ] [ text (lessonTitle lesson) ]
        , div [ class "right", style "left" (px (lessonWidth + 5)) ]
            [ div [ class "tabs" ] <| lessonEditors lesson
            , button [ onClick RunCurrentLesson ] [ text "run" ]
            , preview lesson previewState
            ]
        ]


preview : Lesson -> PreviewState -> Html Msg
preview _ previewState =
    case previewState of
        NoPreview ->
            text "Hit run to show preview"

        Loading ->
            text "loading.."

        Loaded hash ->
            iframe [ src <| "/run/index.html?run=" ++ hash ] []


lessonFiles : Lesson -> List LessonFile
lessonFiles lesson =
    case lesson of
        HtmlIntro { indexHtml } ->
            [ indexHtml ]

        CSSIntro { indexHtml, stylesCss } ->
            [ indexHtml, stylesCss ]


lessonEditors : Lesson -> List (Html Msg)
lessonEditors lesson =
    List.concat <| List.indexedMap fileView <| lessonFiles lesson


fileView : Int -> LessonFile -> List (Html Msg)
fileView pos { filename, content } =
    let
        tabId =
            "tab-" ++ fromInt pos
    in
    [ input [ class "radiotab", name "tabs", tabindex 1, type_ "radio", id tabId ] []
    , label [ class "label", for tabId ] [ text filename ]
    , div [ class "panel", tabindex 1 ] [ textarea [ class "editor", value content, onInput <| ChangeEditor pos ] [] ]
    ]


lessonItemView : Lesson -> Html Msg
lessonItemView lesson =
    li [ onClick <| GotoLesson <| lessonId lesson ] [ text <| lessonTitle lesson ]
