port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Chapters
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Html exposing (Html, a, button, code, div, h1, iframe, input, label, li, nav, p, pre, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, for, id, name, src, style, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Lesson exposing (FileType(..), Lesson, LessonDescription, LessonFile, LessonId(..), lessonIdStr)
import Lessons.CSSInclude as CSSInclude
import Lessons.CSSIntro as CSSIntro exposing (lessonDescription)
import Lessons.CSSRules as CSSRules
import Lessons.ElmIntro as ElmIntro
import Lessons.HtmlAttributes as HtmlAttributes
import Lessons.HtmlIntro as HtmlIntro
import Lessons.HtmlUrlAndImages as HtmlUrlAndImages
import Lessons.JSFunctions as JSFunctions
import Lessons.JSIntro as JSIntro
import Markdown
import Phosphor exposing (IconWeight(..), toHtml)
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


lessonDescriptions : List LessonDescription
lessonDescriptions =
    let
        sum ol lds =
            case ol of
                Chapter ld subOLs ->
                    List.foldr sum (ld :: lds) subOLs
    in
    List.foldr sum [] outline


type Outline
    = Chapter LessonDescription (List Outline)


outline : List Outline
outline =
    [ Chapter Chapters.welcome []
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
    { currentLesson : { lesson : List LessonFile, description : LessonDescription }
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
    ( { currentLesson = { description = Chapters.welcome, lesson = [] }
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
    = GotoLesson LessonId
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


lessonDescriptionById : LessonId -> LessonDescription
lessonDescriptionById target =
    Maybe.withDefault HtmlIntro.lessonDescription <|
        List.head <|
            Debug.log "lesson" <|
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
                | currentLesson = { lesson = description.lessonFiles, description = description }
                , previewState = NoPreview
                , showOutline = False
              }
            , restore ( lessonIdStr description.id, List.length <| lessonEditors description.lessonFiles )
            )

        ( RunCurrentLesson, { lesson } ) ->
            ( { model | previewState = Loading }
            , compile <| filesForRunning lesson
            )

        ( ChangeEditor pos value, current ) ->
            ( { model | currentLesson = { current | lesson = updateEditor current.lesson pos value } }
            , store ( lessonIdStr current.description.id, String.fromInt pos, value )
            )

        ( Compiled hash response, _ ) ->
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

        ( ShowPreview hash, _ ) ->
            ( { model | previewState = Loaded hash }
            , Cmd.none
            )

        ( ToggleTheme, _ ) ->
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

        ( GotRestoredContent contents, current ) ->
            let
                indexedContents =
                    List.indexedMap (\i c -> ( i, c )) contents

                f ( pos, value ) l =
                    updateEditor l pos value

                restoredEditors =
                    List.foldr f current.lesson indexedContents
            in
            ( { model | currentLesson = { current | lesson = restoredEditors } }
            , Cmd.none
            )


filesForRunning : Lesson -> List ( String, String )
filesForRunning lesson =
    List.map (\{ filename, content } -> ( filename, content )) <| lessonFiles lesson


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


themeIcon theme =
    case theme of
        ForceDark ->
            Phosphor.sun

        ForceLight ->
            Phosphor.moon


view : Model -> Html Msg
view model =
    div []
        [ nav [ class "container-fluid" ]
            [ ul []
                [ li []
                    [ span [ onClick ToggleOutline ] [ Phosphor.list Bold |> toHtml [] ]
                    , ul [ classList [ ( "outline", True ), ( "visible", model.showOutline ) ] ] <|
                        List.map outlineView outline
                    ]
                ]
            , ul [] [ li [] [ text "A tour of Elm" ] ]
            , ul []
                [ li [ onClick ToggleTheme ]
                    [ themeIcon model.theme Regular |> toHtml []
                    ]
                ]
            ]
        , if List.isEmpty model.currentLesson.lesson then
            chapterView model.editorsHeight model.lessonWidth model.currentLesson.description

          else
            lessonView model.editorsHeight model.lessonWidth model.currentLesson.lesson model.currentLesson.description model.previewState
        ]


px : Int -> String
px x =
    fromInt x ++ "px"


chapterView : Int -> Int -> LessonDescription -> Html Msg
chapterView editorsHeight lessonWidth { body } =
    div [ class "lessonContainer" ]
        [ div [ Draggable.mouseTrigger VerticalSplit DragMsg, class "separator", style "left" (px lessonWidth) ] []
        , div [ class "left", style "width" (px lessonWidth) ] [ Markdown.toHtml [ class "md-content" ] body ]
        , div [ class "right", style "left" (px (lessonWidth + 10)) ]
            [ div [ Draggable.mouseTrigger HorizontalSplit DragMsg, class "separatorH", style "top" (px editorsHeight) ] []
            , div [ class "editors", style "height" (px editorsHeight) ] [ div [ class "tabs" ] [] ]
            , div [ class "preview", style "top" (px <| editorsHeight + 10) ] [ text "" ]
            ]
        ]


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
    [ Markdown.toHtml [ class "md-content" ] body
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
outlineView (Chapter { id, title } subChapters) =
    let
        chapterLink =
            a [ onClick <| GotoLesson id ] [ text title ]
    in
    if List.isEmpty subChapters then
        li [] [ chapterLink ]

    else
        li [] [ chapterLink, ul [] <| List.map outlineView subChapters ]
