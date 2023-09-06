port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Bytes.Encode
import Chapters exposing (welcome)
import Dict exposing (Dict)
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)
import Editor exposing (Scroll)
import File.Download as Download
import Html exposing (Html, a, button, code, div, iframe, img, input, label, li, nav, ol, pre, span, text, ul)
import Html.Attributes exposing (class, classList, disabled, for, id, name, src, style, tabindex, title, type_, value)
import Html.Events exposing (onClick)
import Html.Lazy
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Lesson exposing (FileType(..), LessonDescription, LessonId(..), lessonIdStr)
import Lessons.CSSInclude as CSSInclude
import Lessons.CSSIntro as CSSIntro exposing (lessonDescription)
import Lessons.CSSRules as CSSRules
import Lessons.Elm.Commands as ElmCommands
import Lessons.Elm.CustomTypes as ElmCustomTypes
import Lessons.Elm.FirstSteps as ElmFirstSteps
import Lessons.Elm.HelloWorld as ElmHelloWorld
import Lessons.Elm.Intro as ElmIntro
import Lessons.Elm.Lang as ElmLang
import Lessons.Elm.Model as ElmModel
import Lessons.Elm.PatternMatching as ElmPatternMatching
import Lessons.Elm.Subscriptions as ElmSubscriptions
import Lessons.Elm.TEA as ElmTEA
import Lessons.Elm.Types as ElmTypes
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
import Time exposing (Posix)
import Zip exposing (Zip)
import Zip.Entry


port store : ( String, String, String ) -> Cmd msg


port restore : ( String, Int ) -> Cmd msg


port reset : ( String, Int ) -> Cmd msg


port restored : (List String -> msg) -> Sub msg


port readyForPreview : (String -> msg) -> Sub msg


port forceTheme : String -> Cmd msg


port lessonChanged : String -> Cmd msg


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
    , Chapter Chapters.spa
        [ Chapter Chapters.html
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
        ]
    , Chapter ElmIntro.lesson
        [ Chapter ElmHelloWorld.lesson []
        , Chapter ElmLang.lesson []
        , Chapter ElmTypes.lesson []
        , Chapter ElmPatternMatching.lesson []
        , Chapter ElmCustomTypes.lesson []
        , Chapter ElmTEA.lesson []
        ]
    , Chapter ElmFirstSteps.lesson
        [ Chapter ElmModel.lesson []
        , Chapter ElmCommands.lesson []
        , Chapter ElmSubscriptions.lesson []
        ]
    ]


allLessonIds : Dict String Outline
allLessonIds =
    List.map (\((Chapter { id } _) as o) -> ( lessonIdStr id, o )) outlineFlat
        |> Dict.fromList


outlineFromHash : String -> Outline
outlineFromHash hash =
    Dict.get (String.dropLeft 1 hash) allLessonIds
        |> Maybe.withDefault welcome


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


type alias Flags =
    ( String, String )


main : Program Flags Model Msg
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
    | LoadingExplanation String
    | FailedWithExplanation String String


type alias OpenLessonFile =
    { filename : String
    , filetype : FileType
    , content : String
    , scroll : Scroll
    }


type alias Model =
    { currentLesson : { currentTab : Maybe Int, openFiles : List OpenLessonFile, outline : Outline }
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


init : ( String, String ) -> ( Model, Cmd Msg )
init ( themeStr, hash ) =
    let
        theme =
            if themeStr == "light" then
                ForceLight

            else
                ForceDark

        ((Chapter upcomingLesson _) as outline) =
            outlineFromHash hash

        openFiles =
            openLesson upcomingLesson

        currentTab =
            if List.isEmpty openFiles then
                Nothing

            else
                Just 0
    in
    ( { currentLesson =
            { openFiles = openFiles
            , outline = outline
            , currentTab = currentTab
            }
      , previewState = NoPreview
      , lessonWidth = 100
      , editorsHeight = 100
      , drag = Draggable.init
      , beingDragged = Nothing
      , showOutline = False
      , theme = theme
      }
    , Cmd.batch
        [ Task.perform GotViewPort getViewport
        , restore ( lessonIdStr upcomingLesson.id, List.length <| upcomingLesson.lessonFiles )
        ]
    )


type Msg
    = GotoLesson Outline
    | SwitchActiveTab Int
    | GotRestoredContent (List String)
    | ShowPreview String
    | RunCurrentLesson
    | GotViewPort Browser.Dom.Viewport
    | OnDragBy Draggable.Delta
    | StartDragging DraggableId
    | DragMsg (Draggable.Msg DraggableId)
    | ToggleOutline
    | Compiled String (Result Http.Error CompileResponse)
    | ExplanationReceived (Result Http.Error ExplainResponse)
    | DismissExplanation
    | ToggleTheme
    | FromEditor EditorMsg
    | ResetCurrentSession
    | RequestExport
    | Export Posix
    | ClickedExplain


type EditorMsg
    = SetText Int String
    | OnScroll Int Scroll


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
            model.currentLesson.openFiles

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

        GotoLesson ((Chapter upcomingLesson _) as outline) ->
            let
                openFiles =
                    openLesson upcomingLesson

                currentTab =
                    if List.isEmpty openFiles then
                        Nothing

                    else
                        Just 0
            in
            ( { model
                | currentLesson = { openFiles = openFiles, outline = outline, currentTab = currentTab }
                , previewState = NoPreview
                , showOutline = False
              }
            , Cmd.batch
                [ restore ( lessonIdStr upcomingLesson.id, List.length <| openFiles )
                , lessonChanged <| lessonIdStr upcomingLesson.id
                ]
            )

        RunCurrentLesson ->
            ( { model | previewState = Loading }
            , compile <| filesForRunning lessonFiles
            )

        ClickedExplain ->
            case model.previewState of
                Failed error ->
                    ( { model | previewState = LoadingExplanation error }
                    , requestExplanation <| filesForRunning lessonFiles
                    )

                _ ->
                    ( model, Cmd.none )

        ExplanationReceived httpRes ->
            let
                previewState =
                    case model.previewState of
                        LoadingExplanation err ->
                            case httpRes of
                                Err _ ->
                                    Failed "An unexpected error occurred"

                                Ok res ->
                                    case res.explanation of
                                        Just explanation ->
                                            FailedWithExplanation err explanation

                                        _ ->
                                            FailedWithExplanation err "Failed to load explanation"

                        _ ->
                            model.previewState
            in
            ( { model | previewState = previewState }
            , Cmd.none
            )

        DismissExplanation ->
            case model.previewState of
                FailedWithExplanation err _ ->
                    ( { model | previewState = Failed err }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        ResetCurrentSession ->
            ( { model | currentLesson = { currentLesson | openFiles = openLesson lessonDescription } }
            , reset ( lessonIdStr lessonDescription.id, List.length <| lessonFiles )
            )

        SwitchActiveTab tab ->
            ( { model | currentLesson = { currentLesson | currentTab = Just tab } }
            , Cmd.none
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
            ( { model | currentLesson = { currentLesson | openFiles = restoredEditors } }
            , Cmd.none
            )

        FromEditor editorMsg ->
            case editorMsg of
                SetText pos codeStr ->
                    let
                        updatedFiles =
                            updateEditor lessonFiles pos codeStr
                    in
                    ( { model | currentLesson = { currentLesson | openFiles = updatedFiles } }
                    , store ( lessonIdStr lessonDescription.id, String.fromInt pos, codeStr )
                    )

                OnScroll pos scroll ->
                    ( { model
                        | currentLesson =
                            { currentLesson
                                | openFiles = updateEditorScroll lessonFiles pos scroll
                            }
                      }
                    , Cmd.none
                    )

        RequestExport ->
            ( model
            , Task.perform Export Time.now
            )

        Export now ->
            let
                downloadName =
                    lessonDescription.title ++ ".zip"

                zip =
                    zipLesson lessonFiles now
            in
            ( model
            , Zip.toBytes zip
                |> Download.bytes downloadName "application/zip"
            )


openLesson : LessonDescription -> List OpenLessonFile
openLesson { lessonFiles } =
    let
        toOpen { filename, filetype, content } =
            { filename = filename
            , filetype = filetype
            , content = content
            , scroll = { top = 0, left = 0 }
            }
    in
    List.map toOpen lessonFiles


filesForRunning : List OpenLessonFile -> List ( String, String )
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


requestExplanation : List ( String, String ) -> Cmd Msg
requestExplanation files =
    let
        bodyString =
            Encode.encode 0 <| payloadEncoder { files = files }

        hash =
            SHA1.toHex <| SHA1.fromString bodyString
    in
    Http.post
        { url = "/explain/" ++ hash
        , body = Http.stringBody "application/json" bodyString
        , expect = Http.expectJson ExplanationReceived explainResponseDecoder
        }


type alias CompileResponse =
    { error : Maybe String }


compileResponseDecoder : Decode.Decoder CompileResponse
compileResponseDecoder =
    Decode.map CompileResponse
        (Decode.field "error" <| Decode.maybe Decode.string)


type alias ExplainResponse =
    { explanation : Maybe String }


explainResponseDecoder : Decode.Decoder ExplainResponse
explainResponseDecoder =
    Decode.map ExplainResponse
        (Decode.field "explanation" <| Decode.maybe Decode.string)


updateEditorScroll : List OpenLessonFile -> Int -> Scroll -> List OpenLessonFile
updateEditorScroll files pos scroll =
    let
        updateFile i file =
            if i == pos then
                { file | scroll = scroll }

            else
                file
    in
    List.indexedMap updateFile files


updateEditor : List OpenLessonFile -> Int -> String -> List OpenLessonFile
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
                [ li [ class "brand", onClick <| GotoLesson welcome ]
                    [ img [ class "tangram", src "/assets/images/elm-tour-logo.svg" ] []
                    , span [] [ text "A tour of Elm" ]
                    ]
                ]
            , ul []
                [ li []
                    [ a [ onClick ToggleOutline, title "Toggle lesson index" ] [ PI.list Bold |> toHtml [] ]
                    , ul [ classList [ ( "outline", True ), ( "visible", model.showOutline ) ] ] <|
                        List.map outlineView <|
                            List.drop 1 outlines
                    ]
                , li [ onClick ToggleTheme, title "Toggle dark/light mode" ]
                    [ themeIcon model.theme Regular |> toHtml []
                    ]
                ]
            ]
        , lessonView model model.editorsHeight model.lessonWidth model.currentLesson model.previewState
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


lessonView : Model -> Int -> Int -> { a | openFiles : List OpenLessonFile, outline : Outline, currentTab : Maybe Int } -> PreviewState -> Html Msg
lessonView model editorsHeight lessonWidth { openFiles, outline, currentTab } previewState =
    let
        (Chapter { body } _) =
            outline
    in
    div [ class "lessonContainer" ]
        [ div [ Draggable.mouseTrigger VerticalSplit DragMsg, class "separator", style "left" (px lessonWidth) ] []
        , div [ class "left", style "width" (px lessonWidth) ]
            [ chapterNavView outline
            , markdown body
            ]
        , div [ class "right", style "left" (px (lessonWidth + 10)) ]
            [ div [ Draggable.mouseTrigger HorizontalSplit DragMsg, class "separatorH", style "top" (px editorsHeight) ] []
            , div [ class "editors", style "height" (px editorsHeight) ]
                [ div [ class "tabs" ] <| actionsView openFiles :: lessonEditors model currentTab openFiles
                ]
            , if List.isEmpty openFiles then
                text ""

              else
                div [ class "preview", style "top" (px <| editorsHeight + 10) ]
                    [ button [ onClick RunCurrentLesson ] [ text "run" ]
                    , preview openFiles previewState
                    ]
            ]
        ]


actionsView : List OpenLessonFile -> Html Msg
actionsView openFiles =
    if List.isEmpty openFiles then
        text ""

    else
        div [ class "editorActions" ]
            [ a [ onClick RequestExport, title "Downolad files as ZIP archive" ] [ regularIcon PI.download ]
            , a [ onClick ResetCurrentSession, title "Reset files to lesson content" ] [ regularIcon PI.trash ]
            ]


preview : List OpenLessonFile -> PreviewState -> Html Msg
preview _ previewState =
    case previewState of
        NoPreview ->
            text "Hit run to show preview"

        Loading ->
            text "loading.."

        Loaded hash ->
            iframe [ src <| "/run/" ++ hash ++ "/index.html" ] []

        Failed msg ->
            div []
                [ button [ onClick ClickedExplain ] [ text "explain" ]
                , pre [] [ code [] [ text msg ] ]
                ]

        LoadingExplanation msg ->
            div []
                [ button [ disabled True ] [ text "explain" ]
                , pre [] [ code [] [ text msg ] ]
                ]

        FailedWithExplanation msg explanation ->
            div []
                [ div [ class "explanation hljs" ]
                    [ PI.x Bold |> toHtml [ onClick DismissExplanation ]
                    , markdown explanation
                    ]
                , pre [] [ code [] [ text msg ] ]
                ]


lessonEditors : Model -> Maybe Int -> List OpenLessonFile -> List (Html Msg)
lessonEditors model openTab files =
    List.concat <| List.indexedMap (fileView model.theme openTab) files


fileView : Theme -> Maybe Int -> Int -> OpenLessonFile -> List (Html Msg)
fileView theme currentTab pos ({ filename } as file) =
    let
        tabId =
            "tab-" ++ fromInt pos

        themeName =
            case theme of
                ForceDark ->
                    "Monokai"

                ForceLight ->
                    "GitHub"

        active =
            currentTab == Just pos
    in
    [ input [ class "radiotab", name "tabs", tabindex 1, type_ "radio", id tabId ] []
    , label
        [ classList [ ( "label", True ), ( "active", active ) ]
        , onClick <| SwitchActiveTab pos
        , for tabId
        ]
        [ text filename ]
    , div [ classList [ ( "panel", True ), ( "active", active ) ], tabindex 1 ]
        [ Html.Lazy.lazy Editor.textareaStyle themeName
        , Html.Lazy.lazy Editor.syntaxThemeStyle themeName
        , Editor.viewLanguage (FromEditor << OnScroll pos) (FromEditor << SetText pos) file
        ]
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


zipLesson : List OpenLessonFile -> Posix -> Zip
zipLesson files now =
    let
        toEntry { filename, content } =
            Bytes.Encode.string content
                |> Bytes.Encode.encode
                |> Zip.Entry.store
                    { path = filename
                    , lastModified = ( Time.utc, now )
                    , comment = Nothing
                    }
    in
    List.map toEntry files
        |> Zip.fromEntries


mdOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Just "html"
    , sanitize = False
    , smartypants = True
    }


markdown =
    Markdown.toHtmlWith mdOptions [ class "md-content" ]
