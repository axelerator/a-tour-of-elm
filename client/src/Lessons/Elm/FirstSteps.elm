module Lessons.Elm.FirstSteps exposing (lesson)

import Lesson exposing (FileType(..), LessonId(..))


lesson =
    { id = ElmFirstSteps
    , title = "First steps"
    , body = body
    , lessonFiles = []
    }


body =
    """### First steps Elm

In this chapter we'll start building a real frontend for a single plage application
starting with a login form.

  """
