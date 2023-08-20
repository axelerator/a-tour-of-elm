port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Html exposing (Html, button, div, iframe, input, label, li, text, textarea, ul)
import Html.Attributes exposing (checked, class, for, id, name, src, style, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Lesson exposing (FileType(..), Lesson(..), LessonFile, LessonId(..), lessonId, lessonIdStr, lessonTitle)
import Lessons.CSSIntro as CSSIntro
import Lessons.HtmlIntro as HtmlIntro
import String exposing (fromInt)
import Task


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
    , lessonWidth : Int
    , editorsHeight : Int
    , drag : Draggable.State DraggableId
    , beingDragged : Maybe DraggableId
    }


type DraggableId
    = VerticalSplit
    | HorizontalSplit


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentLesson = Nothing
      , previewState = NoPreview
      , lessonWidth = 100
      , editorsHeight = 100
      , drag = Draggable.init
      , beingDragged = Nothing
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
    | OnDragBy Draggable.Delta
    | StartDragging DraggableId
    | DragMsg (Draggable.Msg DraggableId)


dragConfig : Draggable.Config DraggableId Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]


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
                currentLesson =
                    case id of
                        HtmlIntroId ->
                            HtmlIntro.lesson

                        CSSIntroId ->
                            CSSIntro.lesson
            in
            ( { model | currentLesson = Just currentLesson, previewState = NoPreview }
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
            Sub.batch
                [ Draggable.subscriptions DragMsg model.drag
                , case model.previewState of
                    Loading ->
                        readyForPreview ShowPreview

                    _ ->
                        restored GotRestoredContent
                ]

        Nothing ->
            Sub.none


view : Model -> Html Msg
view model =
    div []
        [ ul [] <| List.map lessonItemView lessons
        , case model.currentLesson of
            Just lesson ->
                lessonView model.editorsHeight model.lessonWidth lesson model.previewState

            Nothing ->
                text ""
        ]


px : Int -> String
px x =
    fromInt x ++ "px"


lessonView : Int -> Int -> Lesson -> PreviewState -> Html Msg
lessonView editorsHeight lessonWidth lesson previewState =
    div [ class "lessonContainer" ]
        [ div [ Draggable.mouseTrigger VerticalSplit DragMsg, class "separator", style "left" (px lessonWidth) ] []
        , div [ class "left", style "width" (px lessonWidth) ] [ text (lessonTitle lesson) ]
        , div [ class "right", style "left" (px (lessonWidth + 10)) ]
            [ div [ Draggable.mouseTrigger HorizontalSplit DragMsg, class "separatorH", style "top" (px editorsHeight) ] []
            , div [ class "editors", style "height" (px editorsHeight) ] [ div [ class "tabs" ] <| lessonEditors lesson ]
            , div [ class "preview", style "top" (px <| editorsHeight + 10) ] 
                [ button [ onClick RunCurrentLesson ] [ text "run" ]
                , preview lesson previewState
                ]

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
