use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::Duration,
};

use axum::{
    extract::{self, DefaultBodyLimit},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use mime;
use serde::{Deserialize, Serialize};
use tokio::{self, time};
use tower_http::services::{ServeDir, ServeFile};
use walkdir::WalkDir;

use openai::{
    chat::{ChatCompletion, ChatCompletionMessage, ChatCompletionMessageRole},
    set_key,
};

#[tokio::main]
async fn main() {
    clear_cache();
    let serve_dir = ServeDir::new("www/assets").not_found_service(ServeFile::new("www/index.html"));

    let mut app = Router::new()
        .nest_service("/", ServeFile::new("www/index.html"))
        .nest_service("/assets", serve_dir);
    app = app
        .route("/compile/:run", post(compile_handler))
        .route("/explain/:run", post(explain_handler))
        .route("/run/:run_hash/:rest", get(handler))
        .layer(DefaultBodyLimit::max(4096));

    tokio::spawn(async {
        let minutes_10 = 10 * 60 * 1000;
        let mut interval = time::interval(Duration::from_millis(minutes_10));
        loop {
            interval.tick().await;
            clear_cache();
        }
    });

    // run it with hyper on localhost:3000
    axum::Server::bind(&"0.0.0.0:8080".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}

#[derive(Deserialize, Debug)]
struct LessonFiles {
    files: Vec<LessonFile>,
}

#[derive(Deserialize, Debug)]
struct LessonFile {
    filename: String,
    content: String,
}

const CONTENT_TYPE: &str = "Content-Type";

async fn handler(
    axum::extract::Path((run_hash, path)): axum::extract::Path<(String, String)>,
) -> (StatusCode, [(&'static str, String); 1], String) {
    let tmp = PathBuf::from("tmp");
    let file = tmp.join(run_hash).join(path);

    if file.exists() {
        let content_type: mime::Mime = if let Some(extension) = file.extension() {
            match extension.to_string_lossy().to_string().as_str() {
                "html" => mime::TEXT_HTML_UTF_8,
                "css" => mime::TEXT_CSS_UTF_8,
                _ => mime::TEXT_PLAIN,
            }
        } else {
            mime::TEXT_PLAIN
        };
        let content_type_str = content_type.to_string();
        (
            StatusCode::OK,
            [(CONTENT_TYPE, content_type_str)],
            fs::read_to_string(file).unwrap(),
        )
    } else {
        (
            StatusCode::NOT_FOUND,
            [(CONTENT_TYPE, mime::TEXT_PLAIN.to_string())],
            "Not found".to_string(),
        )
    }
}

#[derive(Serialize)]
struct CompileResponse {
    error: Option<String>,
}

async fn compile_handler(
    axum::extract::Path(run_hash): axum::extract::Path<String>,
    extract::Json(lesson_files): extract::Json<LessonFiles>,
) -> Json<CompileResponse> {
    let tmp = PathBuf::from("tmp");
    let elm_boiler_plate = "elm_boiler_plate";
    let elm_boiler_plate_dir = tmp.join(elm_boiler_plate);
    let run_dir = tmp.join(run_hash);
    let build_error_file = run_dir.join("build_error.txt");
    let mut errors = "".to_string();
    if !run_dir.exists() {
        fs::create_dir_all(&run_dir).unwrap();

        let mut compile_elm = false;
        for file in lesson_files.files.iter() {
            if file.filename == "Main.elm" {
                compile_elm = true;
            }
            let path = run_dir.join(&file.filename);
            fs::write(path, file.content.clone()).unwrap();
            if file.filename.ends_with(".html") {
                let make_out = Command::new("npm")
                    .current_dir(&run_dir)
                    .arg("exec")
                    .arg("html-validate")
                    .arg(&file.filename)
                    .output()
                    .expect("Failed to compile");
                if !make_out.status.success() {
                    let build_error = String::from_utf8_lossy(&make_out.stdout).to_string();
                    errors = format!("{errors}\n{0:}\n{build_error}", file.filename);
                }
            }
            if file.filename.ends_with(".css") {
                let make_out = Command::new("npx")
                    .current_dir(&run_dir)
                    .arg("stylelint")
                    .arg(&file.filename)
                    .output()
                    .expect("Failed to compile");
                if !make_out.status.success() {
                    let build_error = String::from_utf8_lossy(&make_out.stderr).to_string();
                    errors = format!("{errors}\n{0:}\n{build_error}", file.filename);
                }
            }
        }

        if compile_elm {
            create_boiler_plate(&elm_boiler_plate_dir);

            let _copy_boilerplate = Command::new("cp")
                .arg("-r")
                .arg(&elm_boiler_plate_dir)
                .arg(run_dir.join("elm"))
                .spawn()
                .expect("Failed to copy copy_boilerplate")
                .wait();

            copy_files_with_extension(&run_dir, &run_dir.join("elm").join("src"), "elm").unwrap();

            let make_out = Command::new("npx")
                .current_dir(&run_dir.join("elm"))
                .arg("elm")
                .arg("make")
                .arg("src/Main.elm")
                .arg("--output=../main.js")
                .output()
                .expect("Failed to compile");
            if !make_out.status.success() {
                let build_error = String::from_utf8_lossy(&make_out.stderr).to_string();
                errors = format!("{errors}\n{build_error}");
            }
        }
        if errors == "" {
            return Json(CompileResponse { error: None });
        } else {
            fs::write(build_error_file, errors.clone()).unwrap();
            return Json(CompileResponse {
                error: Some(errors),
            });
        }
    } else {
        if build_error_file.exists() {
            return Json(CompileResponse {
                error: Some(fs::read_to_string(build_error_file).unwrap()),
            });
        } else {
            return Json(CompileResponse { error: None });
        }
    }
}

#[derive(Serialize)]
struct ExplainResponse {
    explanation: Option<String>,
}

const OPENAI_CONTENT: &'static str = 
    r#"You are an expert web developer and patient teacher. 
    You play the role of a knowledgable mentor in an interactive programming tutorial.
    Students will give you a set of source files and an error message generated by a
    validator or the Elm compiler.
    When you give advice don't include a listing of the corrected code."#;

async fn explain_handler(
    axum::extract::Path(run_hash): axum::extract::Path<String>,
) -> Json<ExplainResponse> {
    let tmp = PathBuf::from("tmp");
    let run_dir = tmp.join(&run_hash);
    let stored_explanation = run_dir.join("explanation.txt");
    let mut error = None;
    let mut files = vec![];
    if run_dir.exists() {
        println!("Expl: {:?}", stored_explanation);
        if stored_explanation.exists() {
            println!("Returning cached explanation");
            let stored_explanation = fs::read_to_string(stored_explanation).unwrap();

            return Json(ExplainResponse {
                explanation: Some(stored_explanation),
            });
        }

        for entry in WalkDir::new(run_dir).into_iter().filter_map(|e| e.ok()) {
            if entry.file_type().is_file() {
                if entry.file_name() == "build_error.txt" {
                    error = Some(fs::read_to_string(entry.path()).unwrap());
                } else {
                    let file_name = entry.file_name().to_string_lossy().to_string();
                    let file_content = fs::read_to_string(entry.path()).unwrap();
                    files.push((file_name, file_content));
                }
            }
        }

        if let Some(error_text) = error {
            let fp = if files.len() == 1 {
                "is the one file".to_string()
            } else {
                format!("are the {} files", files.len())
            };

            let file_listings: Vec<String> = files
                .into_iter()
                .map(|(file_name, file_content)| format!("{file_name}:\n```\n{file_content}\n```"))
                .collect();
            let file_listings = file_listings.join("\n");

            let question =
                format!("Here {fp} of the current lesson.\n{file_listings}\n I got the following errors:\n```{error_text}```\n. Please explain in simple terms what's the problem, but don't include the complete listing of the fixed code in your answer.");
        

            // Make sure you have a file named `.env` with the `OPENAI_KEY` environment variable defined!
            //dotenv().unwrap();
            set_key("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".to_string());

            let setup_msg = ChatCompletionMessage {
                role: ChatCompletionMessageRole::System,
                content: Some(OPENAI_CONTENT.to_string()),
                name: None,
                function_call: None,
            };

            let message = ChatCompletionMessage {
                role: ChatCompletionMessageRole::User,
                content: Some(question),
                name: None,
                function_call: None,
            };
            let messages = vec![setup_msg, message];

            let chat_completion = ChatCompletion::builder("gpt-3.5-turbo", messages.clone())
                .create()
                .await
                .unwrap();
            for choice in chat_completion.choices.iter() {
                println!("Usage: {}: {:?}", choice.index, choice.finish_reason);
            }
            let returned_message = chat_completion.choices.first().unwrap().message.clone();

            let explanation = returned_message.content.clone().unwrap();
            let explanation = explanation.trim();

            fs::write(stored_explanation, explanation).unwrap();

            Json(ExplainResponse {
                explanation: Some(explanation.to_string()),
            })
        } else {
            Json(ExplainResponse {
                explanation: Some(run_hash.to_string()),
            })
        }
    } else {
        Json(ExplainResponse { explanation: None })
    }
}

fn copy_files_with_extension(
    source_folder: &Path,
    target_folder: &Path,
    target_extension: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    for entry in WalkDir::new(source_folder)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.file_type().is_file() {
            let source_path = entry.path();
            if let Some(extension) = source_path.extension() {
                if extension == target_extension {
                    let target_path = target_folder.join(source_path.file_name().unwrap());
                    // for some reason fs::copy results in an empty file
                    //fs::copy(source_path, &target_path)?;
                    fs::write(target_path, fs::read_to_string(source_path).unwrap()).unwrap();
                }
            }
        }
    }
    Ok(())
}

fn clear_cache() {
    let tmp = PathBuf::from("tmp");
    if tmp.exists() {
        let _ = Command::new("find")
            .current_dir(tmp)
            .arg(".")
            .arg("-mindepth")
            .arg("1")
            .arg("-maxdepth")
            .arg("1")
            .arg("-type")
            .arg("d")
            .arg("!")
            .arg("-name")
            .arg("elm_boiler_plate")
            .arg("-exec")
            .arg("rm")
            .arg("-rf")
            .arg("{}")
            .arg(";")
            .spawn()
            .expect("Failed to clean cache")
            .wait();
    }
}

fn create_boiler_plate(elm_boiler_plate_dir: &Path) {
    if !elm_boiler_plate_dir.exists() {
        fs::create_dir_all(&elm_boiler_plate_dir).unwrap();
        let yes = Command::new("yes")
            .stdout(Stdio::piped())
            .spawn()
            .expect("Failed to start yes process");
        let yes_out = yes.stdout.expect("Failed to open echo stdout");

        let elm_init = Command::new("npx")
            .current_dir(&elm_boiler_plate_dir)
            .arg("elm")
            .arg("init")
            .stdin(Stdio::from(yes_out))
            .stdout(Stdio::piped())
            .spawn()
            .expect("Failed to swapn elm init");
        let _output = elm_init.wait_with_output().expect("Failed to wait on sed");

        let main = r#"module Main exposing (main)
import Html exposing (text)

main = text "Hello!"
"#;
        fs::write(elm_boiler_plate_dir.join("src").join("Main.elm"), main).unwrap();

        let _make_out = Command::new("elm")
            .current_dir(&elm_boiler_plate_dir)
            .arg("make")
            .arg("src/Main.elm")
            .arg("--output=main.js")
            .output()
            .expect("Failed to compile");
        //make.wait();

        //output.status
        // Execute `ls` in the current directory of the program.
    }
}
