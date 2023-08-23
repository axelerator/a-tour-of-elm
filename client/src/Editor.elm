module Editor exposing (Scroll, syntaxThemeStyle, textareaStyle, viewLanguage)

import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, spellcheck, style, value)
import Html.Events exposing (onInput)
import Html.Lazy
import Json.Decode as Decode
import Lesson exposing (FileType(..))
import Parser
import SyntaxHighlight as SH


toHtmlElm : Maybe Int -> String -> HighlightModel -> Html msg
toHtmlElm =
    codeToHtml SH.elm


toHtmlXml : Maybe Int -> String -> HighlightModel -> Html msg
toHtmlXml =
    codeToHtml SH.xml


toHtmlJavascript : Maybe Int -> String -> HighlightModel -> Html msg
toHtmlJavascript =
    codeToHtml SH.javascript


toHtmlCss : Maybe Int -> String -> HighlightModel -> Html msg
toHtmlCss =
    codeToHtml SH.css


codeToHtml : (String -> Result (List Parser.DeadEnd) SH.HCode) -> Maybe Int -> String -> HighlightModel -> Html msg
codeToHtml parser maybeStart str hlModel =
    parser str
        |> Result.map (SH.highlightLines hlModel.mode hlModel.start hlModel.end)
        |> Result.map (SH.toBlockHtml maybeStart)
        |> Result.mapError Parser.deadEndsToString
        |> (\result ->
                case result of
                    Result.Ok a ->
                        a

                    Result.Err x ->
                        text x
           )


textareaStyle : String -> Html msg
textareaStyle theme =
    let
        style a b =
            Html.node "style"
                []
                [ text
                    (String.join "\n"
                        [ ".textarea {caret-color: " ++ a ++ ";}"
                        , ".textarea::selection { background-color: " ++ b ++ "; }"
                        ]
                    )
                ]
    in
    if List.member theme [ "Monokai", "One Dark", "Custom" ] then
        style "#f8f8f2" "rgba(255,255,255,0.2)"

    else
        style "#24292e" "rgba(0,0,0,0.2)"


type alias Scroll =
    { top : Float
    , left : Float
    }


defaultHighlightModel : HighlightModel
defaultHighlightModel =
    { mode = Nothing
    , start = 0
    , end = 0
    }


type alias HighlightModel =
    { mode : Maybe SH.Highlight
    , start : Int
    , end : Int
    }


syntaxThemeStyle : String -> Html msg
syntaxThemeStyle selectedTheme =
    case selectedTheme of
        "Monokai" ->
            SH.useTheme SH.monokai

        "GitHub" ->
            SH.useTheme SH.gitHub

        "One Dark" ->
            SH.useTheme SH.oneDark

        _ ->
            SH.useTheme SH.monokai



--viewLanguage : Int -> OpenLessonFile -> Html msg


viewLanguage onScroll_ onInput_ { scroll, content, filetype } =
    let
        parser =
            case filetype of
                ElmFile ->
                    toHtmlElm

                HtmlFile ->
                    toHtmlXml

                JSFile ->
                    toHtmlJavascript

                CSSFile ->
                    toHtmlCss
    in
    div
        [ classList
            [ ( "container", True )
            , ( "elmsh", True )
            ]
        ]
        [ div
            [ class "view-container"
            , style "transform"
                ("translate("
                    ++ String.fromFloat -scroll.left
                    ++ "px, "
                    ++ String.fromFloat -scroll.top
                    ++ "px)"
                )
            , style "will-change" "transform"
            ]
            [ Html.Lazy.lazy3 parser
                (Just 1)
                content
                defaultHighlightModel
            ]
        , viewTextarea onScroll_ onInput_ content
        ]


viewTextarea : (Scroll -> msg) -> (String -> msg) -> String -> Html msg
viewTextarea onScroll_ onInput_ codeStr =
    textarea
        [ value codeStr
        , classList
            [ ( "textarea", True )
            , ( "textarea-lc", True )
            ]
        , onInput onInput_
        , spellcheck False
        , Html.Events.on "scroll"
            (Decode.map2 Scroll
                (Decode.at [ "target", "scrollTop" ] Decode.float)
                (Decode.at [ "target", "scrollLeft" ] Decode.float)
                |> Decode.map onScroll_
            )
        ]
        []
