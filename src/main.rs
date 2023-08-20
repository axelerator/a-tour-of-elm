use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

use axum::{http::StatusCode, routing::get, Router};
use mime;
use serde::Deserialize;
use serde_json;
use tokio;
use tower_cookies::{CookieManagerLayer, Cookies};
use tower_http::services::{ServeDir, ServeFile};
use walkdir::WalkDir;

#[tokio::main]
async fn main() {
    clear_cache();
    let serve_dir = ServeDir::new("www/assets").not_found_service(ServeFile::new("www/index.html"));

    let mut app = Router::new()
        .nest_service("/", ServeFile::new("www/index.html"))
        .nest_service("/assets", serve_dir);
    app = app
        .route("/run/:rest", get(handler))
        .layer(CookieManagerLayer::new());

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
const RUN_COOKIE_NAME: &str = "run";
const COOKIE_NAME: &str = "lessonFiles";

async fn handler(
    axum::extract::Path(path): axum::extract::Path<String>,
    cookies: Cookies,
) -> (StatusCode, [(&'static str, String); 1], String) {
    let run_hash: String = cookies
        .get(RUN_COOKIE_NAME)
        .map(|c| c.value().to_string())
        .unwrap();
    let lesson_files: LessonFiles = cookies
        .get(COOKIE_NAME)
        .map(|c| serde_json::from_str(&c.value()).unwrap())
        .unwrap();

    println!("Run {}", run_hash);
    let tmp = PathBuf::from("tmp");
    let elm_boiler_plate = "elm_boiler_plate";
    let elm_boiler_plate_dir = tmp.join(elm_boiler_plate);
    let run_dir = tmp.join(run_hash);
    if !run_dir.exists() {
        fs::create_dir_all(&run_dir).unwrap();

        let mut compile_elm = true;
        for file in lesson_files.files.iter() {
            if file.filename == "Main.elm" {
                compile_elm = true;
            }
            let path = run_dir.join(&file.filename);
            fs::write(path, file.content.clone()).unwrap();
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

            let _make = Command::new("elm")
                .current_dir(&run_dir.join("elm"))
                .arg("make")
                .arg("src/Main.elm")
                .arg("--output=../main.js")
                .spawn()
                .expect("Failed to compile")
                .wait();
        }
    }
    let file = run_dir.join(path);

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
                    println!(
                        "source: {:?} {:?}",
                        source_path,
                        fs::read_to_string(source_path).unwrap()
                    );
                    println!("target {:?}", target_path);
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

        let elm_init = Command::new("elm")
            .current_dir(&elm_boiler_plate_dir)
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

        let _make = Command::new("elm")
            .current_dir(&elm_boiler_plate_dir)
            .arg("make")
            .arg("src/Main.elm")
            .arg("--output=main.js")
            .spawn()
            .expect("Failed to compile")
            .wait();
        //make.wait();

        //output.status
        // Execute `ls` in the current directory of the program.
    }
}
