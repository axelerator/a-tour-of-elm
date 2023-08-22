port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Chapters
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Html exposing (Html, a, button, code, div, iframe, img, input, label, li, nav, ol, pre, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, for, id, name, src, style, tabindex, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Lesson exposing (FileType(..), Lesson, LessonDescription, LessonFile, LessonId(..), lessonIdStr)
import Lessons.CSSInclude as CSSInclude
import Lessons.CSSIntro as CSSIntro
import Lessons.CSSRules as CSSRules
import Lessons.ElmIntro as ElmIntro
import Lessons.HtmlAttributes as HtmlAttributes
import Lessons.HtmlIntro as HtmlIntro
import Lessons.HtmlUrlAndImages as HtmlUrlAndImages
import Lessons.JSFunctions as JSFunctions
import Lessons.JSIntro as JSIntro
import Markdown
import Phosphor as PI exposing (IconVariant, IconWeight(..), toHtml)
import SHA1
import String exposing (fromInt)
import Task


port store : ( String, String, String ) -> Cmd msg


port restore : ( String, Int ) -> Cmd msg


port restored : (List String -> msg) -> Sub msg


port readyForPreview : (String -> msg) -> Sub msg


port forceTheme : String -> Cmd msg


type Theme
    = ForceDark
    | ForceLight


type Outline
    = Chapter LessonDescription (List Outline)


welcome : Outline
welcome =
    Chapter Chapters.welcome []


outlines : List Outline
outlines =
    [ welcome
    , Chapter Chapters.html
        [ Chapter HtmlIntro.lessonDescription []
        , Chapter HtmlAttributes.lesson []
        , Chapter HtmlUrlAndImages.lesson []
        ]
    , Chapter Chapters.css
        [ Chapter CSSIntro.lessonDescription []
        , Chapter CSSRules.lesson []
        , Chapter CSSInclude.lesson []
        ]
    , Chapter Chapters.js
        [ Chapter JSIntro.lesson []
        , Chapter JSFunctions.lesson []
        ]
    , Chapter Chapters.elm
        [ Chapter ElmIntro.lessonDescription []
        ]
    ]


outlineFlat : List Outline
outlineFlat =
    let
        sum ((Chapter _ subOLs) as self) ols =
            let
                descendants =
                    List.foldr sum [] subOLs
            in
            self :: (descendants ++ ols)
    in
    List.foldr sum [] outlines


nextLesson : Outline -> Maybe Outline
nextLesson prev =
    dropWhile ((/=) prev) outlineFlat |> List.drop 1 |> List.head


prevLesson : Outline -> Maybe Outline
prevLesson prev =
    dropWhile ((/=) prev) (List.reverse outlineFlat) |> List.drop 1 |> List.head


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
    | Failed String


type alias Model =
    { currentLesson : { lesson : List LessonFile, outline : Outline }
    , previewState : PreviewState
    , lessonWidth : Int
    , editorsHeight : Int
    , drag : Draggable.State DraggableId
    , beingDragged : Maybe DraggableId
    , showOutline : Bool
    , theme : Theme
    }


type DraggableId
    = VerticalSplit
    | HorizontalSplit


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentLesson = { lesson = [], outline = welcome }
      , previewState = NoPreview
      , lessonWidth = 100
      , editorsHeight = 100
      , drag = Draggable.init
      , beingDragged = Nothing
      , showOutline = False
      , theme = ForceDark
      }
    , Task.perform GotViewPort getViewport
    )


type Msg
    = GotoLesson Outline
    | ChangeEditor Int String
    | GotRestoredContent (List String)
    | ShowPreview String
    | RunCurrentLesson
    | GotViewPort Browser.Dom.Viewport
    | OnDragBy Draggable.Delta
    | StartDragging DraggableId
    | DragMsg (Draggable.Msg DraggableId)
    | ToggleOutline
    | Compiled String (Result Http.Error CompileResponse)
    | ToggleTheme


dragConfig : Draggable.Config DraggableId Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        lessonFiles =
            model.currentLesson.lesson

        (Chapter lessonDescription _) =
            model.currentLesson.outline

        currentLesson =
            model.currentLesson
    in
    case msg of
        StartDragging id ->
            ( { model | beingDragged = Just id }, Cmd.none )

        OnDragBy ( dx, dy ) ->
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

        ToggleOutline ->
            ( { model | showOutline = not model.showOutline }
            , Cmd.none
            )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        GotViewPort vp ->
            ( { model
                | lessonWidth = round <| 0.5 * vp.viewport.width
                , editorsHeight = round <| 0.5 * vp.viewport.height
              }
            , Cmd.none
            )

        GotoLesson outline ->
            ( { model
                | currentLesson = { lesson = lessonDescription.lessonFiles, outline = outline }
                , previewState = NoPreview
                , showOutline = False
              }
            , restore ( lessonIdStr lessonDescription.id, List.length <| lessonEditors lessonDescription.lessonFiles )
            )

        RunCurrentLesson ->
            ( { model | previewState = Loading }
            , compile <| filesForRunning lessonFiles
            )

        ChangeEditor pos value ->
            ( { model | currentLesson = { currentLesson | lesson = updateEditor lessonFiles pos value } }
            , store ( lessonIdStr lessonDescription.id, String.fromInt pos, value )
            )

        Compiled hash response ->
            let
                previewState =
                    case response of
                        Err _ ->
                            Failed "An unexpected error occurred"

                        Ok { error } ->
                            case error of
                                Nothing ->
                                    Loaded hash

                                Just errorStr ->
                                    Failed errorStr
            in
            ( { model | previewState = previewState }
            , Cmd.none
            )

        ShowPreview hash ->
            ( { model | previewState = Loaded hash }
            , Cmd.none
            )

        ToggleTheme ->
            let
                ( theme, themeStr ) =
                    case model.theme of
                        ForceDark ->
                            ( ForceLight, "light" )

                        ForceLight ->
                            ( ForceDark, "dark" )
            in
            ( { model | theme = theme }
            , forceTheme themeStr
            )

        GotRestoredContent contents ->
            let
                indexedContents =
                    List.indexedMap (\i c -> ( i, c )) contents

                f ( pos, value ) l =
                    updateEditor l pos value

                restoredEditors =
                    List.foldr f lessonFiles indexedContents
            in
            ( { model | currentLesson = { currentLesson | lesson = restoredEditors } }
            , Cmd.none
            )


filesForRunning : Lesson -> List ( String, String )
filesForRunning lessonFiles =
    List.map (\{ filename, content } -> ( filename, content )) <| lessonFiles


type alias CompilePayload =
    { files : List ( String, String ) }


payloadEncoder : CompilePayload -> Encode.Value
payloadEncoder { files } =
    let
        fileEncoder : ( String, String ) -> Encode.Value
        fileEncoder ( filename, content ) =
            Encode.object
                [ ( "filename", Encode.string filename )
                , ( "content", Encode.string content )
                ]

        filesValue : Encode.Value
        filesValue =
            Encode.list fileEncoder files
    in
    Encode.object [ ( "files", filesValue ) ]


compile : List ( String, String ) -> Cmd Msg
compile files =
    let
        bodyString =
            Encode.encode 0 <| payloadEncoder { files = files }

        hash =
            SHA1.toHex <| SHA1.fromString bodyString
    in
    Http.post
        { url = "/compile/" ++ hash
        , body = Http.stringBody "application/json" bodyString
        , expect = Http.expectJson (Compiled hash) compileResponseDecoder
        }


type alias CompileResponse =
    { error : Maybe String }


compileResponseDecoder : Decode.Decoder CompileResponse
compileResponseDecoder =
    Decode.map CompileResponse
        (Decode.field "error" <| Decode.maybe Decode.string)


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
    Sub.batch
        [ Draggable.subscriptions DragMsg model.drag
        , case model.previewState of
            Loading ->
                readyForPreview ShowPreview

            _ ->
                restored GotRestoredContent
        ]


themeIcon : Theme -> IconWeight -> IconVariant
themeIcon theme =
    case theme of
        ForceDark ->
            PI.sun

        ForceLight ->
            PI.moon


view : Model -> Html Msg
view model =
    div []
        [ nav [ class "container-fluid" ]
            [ ul []
                [ li []
                    [ text "A tour of Elm"
                    , img [ class "tangram", src "/assets/images/tangram.png" ] []
                    ]
                ]
            , ul []
                [ li []
                    [ a [ onClick ToggleOutline ] [ PI.list Bold |> toHtml [] ]
                    , ul [ classList [ ( "outline", True ), ( "visible", model.showOutline ) ] ] <|
                        List.map outlineView outlines
                    ]
                , li [ onClick ToggleTheme ]
                    [ themeIcon model.theme Regular |> toHtml []
                    ]
                ]
            ]
        , lessonView model.editorsHeight model.lessonWidth model.currentLesson model.previewState
        ]


px : Int -> String
px x =
    fromInt x ++ "px"


chapterNavView : Outline -> Html Msg
chapterNavView current =
    let
        nextLink =
            case nextLesson current of
                Just ol ->
                    a [ onClick <| GotoLesson ol, title "Next lesson" ] [ regularIcon PI.skipForward ]

                Nothing ->
                    span [] [ regularIcon PI.skipForward ]

        prevLink =
            case prevLesson current of
                Just ol ->
                    a [ onClick <| GotoLesson ol, title "Previous lesson" ] [ regularIcon PI.skipBack ]

                Nothing ->
                    span [] [ regularIcon PI.skipBack ]
    in
    div [ class "chapterNav" ] [ prevLink, nextLink ]


regularIcon : (IconWeight -> IconVariant) -> Html msg
regularIcon i =
    i Regular |> toHtml []


lessonView : Int -> Int -> { a | lesson : List LessonFile, outline : Outline } -> PreviewState -> Html Msg
lessonView editorsHeight lessonWidth { lesson, outline } previewState =
    let
        (Chapter { body } _) =
            outline
    in
    div [ class "lessonContainer" ]
        [ div [ Draggable.mouseTrigger VerticalSplit DragMsg, class "separator", style "left" (px lessonWidth) ] []
        , div [ class "left", style "width" (px lessonWidth) ]
            [ chapterNavView outline
            , Markdown.toHtml [ class "md-content" ] body
            ]
        , div [ class "right", style "left" (px (lessonWidth + 10)) ]
            [ div [ Draggable.mouseTrigger HorizontalSplit DragMsg, class "separatorH", style "top" (px editorsHeight) ] []
            , div [ class "editors", style "height" (px editorsHeight) ] [ div [ class "tabs" ] <| lessonEditors lesson ]
            , if List.isEmpty lesson then
                text ""

              else
                div [ class "preview", style "top" (px <| editorsHeight + 10) ]
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
            iframe [ src <| "/run/" ++ hash ++ "/index.html" ] []

        Failed msg ->
            pre [] [ code [] [ text msg ] ]


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


outlineView : Outline -> Html Msg
outlineView ol =
    let
        (Chapter { title } subChapters) =
            ol

        chapterLink =
            a [ onClick <| GotoLesson ol ] [ text title ]
    in
    if List.isEmpty subChapters then
        li [] [ chapterLink ]

    else
        li [] [ chapterLink, ul [] <| List.map outlineView subChapters ]


{-| Drop elements in order as long as the predicate evaluates to `True`
taken from <https://github.com/elm-community/list-extra/blob/8.7.0/src/List/Extra.elm>
-}
dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                dropWhile predicate xs

            else
                list
