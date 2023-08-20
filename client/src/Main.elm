port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Html exposing (Html, a, button, div, h1, iframe, input, label, li, nav, p, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, for, id, name, src, style, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Lesson exposing (FileType(..), Lesson, LessonDescription, LessonFile, LessonId(..), lessonIdStr)
import Lessons.CSSIntro as CSSIntro
import Lessons.ElmIntro as ElmIntro
import Lessons.HtmlIntro as HtmlIntro
import Markdown
import String exposing (fromInt)
import Task


port store : ( String, String, String ) -> Cmd msg


port restore : ( String, Int ) -> Cmd msg


port restored : (List String -> msg) -> Sub msg


port run : List ( String, String ) -> Cmd msg


port readyForPreview : (String -> msg) -> Sub msg


lessonDescriptions : List LessonDescription
lessonDescriptions =
    [ HtmlIntro.lessonDescription
    , CSSIntro.lessonDescription
    , ElmIntro.lessonDescription
    ]


type alias ChapterContent =
    { title : String
    , body : String
    }


type Outline
    = Chapter ChapterContent (List Outline)
    | Lesson LessonDescription


welcome : ChapterContent
welcome =
    { title = "Welcome"
    , body = "Hi there!"
    }


htmlChapterContent : ChapterContent
htmlChapterContent =
    { title = "What is HTML?"
    , body = "Hi there!"
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


outline : List Outline
outline =
    [ Chapter welcome []
    , Chapter htmlChapterContent [ Lesson HtmlIntro.lessonDescription ]
    , Chapter cssChapterContent [ Lesson CSSIntro.lessonDescription ]
    , Chapter elmChapterContent [ Lesson ElmIntro.lessonDescription ]
    ]



-- TODO: make recursive


findChapter : String -> ChapterContent
findChapter targetTitle =
    let
        chapterWithTitle : Outline -> Bool
        chapterWithTitle o =
            case o of
                Chapter { title } _ ->
                    title == targetTitle

                _ ->
                    False

        result =
            List.head <| List.filter chapterWithTitle outline
    in
    case result of
        Just (Chapter content _) ->
            content

        _ ->
            welcome


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


type CurrentPage
    = CurrentLesson { lesson : List LessonFile, description : LessonDescription }
    | CurrentChapter ChapterContent


type alias Model =
    { currentLesson : CurrentPage
    , previewState : PreviewState
    , lessonWidth : Int
    , editorsHeight : Int
    , drag : Draggable.State DraggableId
    , beingDragged : Maybe DraggableId
    , showOutline : Bool
    }


type DraggableId
    = VerticalSplit
    | HorizontalSplit


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentLesson = CurrentChapter welcome
      , previewState = NoPreview
      , lessonWidth = 100
      , editorsHeight = 100
      , drag = Draggable.init
      , beingDragged = Nothing
      , showOutline = False
      }
    , Task.perform GotViewPort getViewport
    )


type Msg
    = GotoLesson LessonId
    | GotoChapter String
    | ChangeEditor Int String
    | GotRestoredContent (List String)
    | ShowPreview String
    | RunCurrentLesson
    | GotViewPort Browser.Dom.Viewport
    | OnDragBy Draggable.Delta
    | StartDragging DraggableId
    | DragMsg (Draggable.Msg DraggableId)
    | ToggleOutline


dragConfig : Draggable.Config DraggableId Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]


lessonDescriptionById : LessonId -> LessonDescription
lessonDescriptionById target =
    Maybe.withDefault HtmlIntro.lessonDescription <|
        List.head <|
            List.filter (.id >> (==) target) lessonDescriptions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.currentLesson ) of
        ( StartDragging id, _ ) ->
            ( { model | beingDragged = Just id }, Cmd.none )

        ( OnDragBy ( dx, dy ), _ ) ->
            let
                model_ =
                    case model.beingDragged of
                        Just HorizontalSplit ->
                            { model | editorsHeight = model.editorsHeight + round dy }

                        Just VerticalSplit ->
                            { model | lessonWidth = model.lessonWidth + round dx }

                        Nothing ->
                            model
            in
            ( model_
            , Cmd.none
            )

        ( ToggleOutline, _ ) ->
            ( { model | showOutline = not model.showOutline }
            , Cmd.none
            )

        ( DragMsg dragMsg, _ ) ->
            Draggable.update dragConfig dragMsg model

        ( GotViewPort vp, _ ) ->
            ( { model
                | lessonWidth = round <| 0.5 * vp.viewport.width
                , editorsHeight = round <| 0.5 * vp.viewport.height
              }
            , Cmd.none
            )

        ( GotoLesson id, _ ) ->
            let
                description =
                    lessonDescriptionById id
            in
            ( { model
                | currentLesson = CurrentLesson { lesson = description.lessonFiles, description = description }
                , previewState = NoPreview
                , showOutline = False
              }
            , restore ( lessonIdStr description.id, List.length <| lessonEditors description.lessonFiles )
            )

        ( GotoChapter title, _ ) ->
            ( { model
                | currentLesson = CurrentChapter (findChapter title)
                , previewState = NoPreview
                , showOutline = False
              }
            , Cmd.none
            )

        ( RunCurrentLesson, CurrentLesson { lesson } ) ->
            ( { model | previewState = Loading }
            , run <| filesForRunning lesson
            )

        ( ChangeEditor pos value, CurrentLesson current ) ->
            ( { model | currentLesson = CurrentLesson { current | lesson = updateEditor current.lesson pos value } }
            , store ( lessonIdStr current.description.id, String.fromInt pos, value )
            )

        ( ShowPreview hash, _ ) ->
            ( { model | previewState = Loaded hash }
            , Cmd.none
            )

        ( GotRestoredContent contents, CurrentLesson current ) ->
            let
                indexedContents =
                    List.indexedMap (\i c -> ( i, c )) contents

                f ( pos, value ) l =
                    updateEditor l pos value

                restoredEditors =
                    List.foldr f current.lesson indexedContents
            in
            ( { model | currentLesson = CurrentLesson <| { current | lesson = restoredEditors } }
            , Cmd.none
            )

        _ ->
            ( model
            , Cmd.none
            )


filesForRunning : Lesson -> List ( String, String )
filesForRunning lesson =
    List.map (\{ filename, content } -> ( filename, content )) <| lessonFiles lesson


updateEditor : List LessonFile -> Int -> String -> List LessonFile
updateEditor files pos value =
    let
        updateFile i file =
            if i == pos && value /= "NOT YET STORED" then
                { file | content = value }

            else
                file
    in
    List.indexedMap updateFile files


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.currentLesson of
        CurrentLesson _ ->
            Sub.batch
                [ Draggable.subscriptions DragMsg model.drag
                , case model.previewState of
                    Loading ->
                        readyForPreview ShowPreview

                    _ ->
                        restored GotRestoredContent
                ]

        _ ->
            Sub.none


view : Model -> Html Msg
view model =
    div []
        [ nav []
            [ ul []
                [ li []
                    [ span [ onClick ToggleOutline ] [ text "Lessons" ]
                    , div [ classList [ ( "outline", True ), ( "visible", model.showOutline ) ] ] <|
                        List.map outlineView outline
                    ]
                ]
            ]
        , case model.currentLesson of
            CurrentLesson { lesson, description } ->
                lessonView model.editorsHeight model.lessonWidth lesson description model.previewState

            CurrentChapter {title, body} ->
              div []
                [h1 [] [text title]
                , Markdown.toHtml [class "content"] body
                ]
        ]


px : Int -> String
px x =
    fromInt x ++ "px"


lessonView : Int -> Int -> Lesson -> LessonDescription -> PreviewState -> Html Msg
lessonView editorsHeight lessonWidth lesson description previewState =
    div [ class "lessonContainer" ]
        [ div [ Draggable.mouseTrigger VerticalSplit DragMsg, class "separator", style "left" (px lessonWidth) ] []
        , div [ class "left", style "width" (px lessonWidth) ] <| lessonContentView description
        , div [ class "right", style "left" (px (lessonWidth + 10)) ]
            [ div [ Draggable.mouseTrigger HorizontalSplit DragMsg, class "separatorH", style "top" (px editorsHeight) ] []
            , div [ class "editors", style "height" (px editorsHeight) ] [ div [ class "tabs" ] <| lessonEditors lesson ]
            , div [ class "preview", style "top" (px <| editorsHeight + 10) ]
                [ button [ onClick RunCurrentLesson ] [ text "run" ]
                , preview lesson previewState
                ]
            ]
        ]


lessonContentView : LessonDescription -> List (Html Msg)
lessonContentView { title, body } =
    [ h1 [] [ text title ]
    , Markdown.toHtml [ class "content" ] body
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
lessonFiles files =
    files


lessonEditors : List LessonFile -> List (Html Msg)
lessonEditors files =
    List.concat <| List.indexedMap fileView files


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


lessonItemView : LessonDescription -> Html Msg
lessonItemView ld =
    li [ onClick <| GotoLesson ld.id ] [ text ld.title ]


outlineView : Outline -> Html Msg
outlineView ol =
    case ol of
        Chapter { title } subChapters ->
            div [] [ a [onClick <| GotoChapter title] [ text title ], ul [] <| List.map outlineView subChapters ]

        Lesson { title, id } ->
            li [ onClick <| GotoLesson id ] [ a [] [ text title ] ]
