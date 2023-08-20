use std::{path::PathBuf, fs};

use axum::{
    http::StatusCode,
    routing::get,
    Router,
};
use serde::Deserialize;
use serde_json;
use tokio;
use tower_cookies::{CookieManagerLayer, Cookies};
use tower_http::services::{ServeDir, ServeFile};
use mime;

#[tokio::main]
async fn main() {
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
        .map(|c| c.value().to_string() )
        .unwrap();
    let lesson_files: LessonFiles = cookies
        .get(COOKIE_NAME)
        .map(|c| serde_json::from_str(&c.value()).unwrap() )
        .unwrap();

    println!("Run {}", run_hash);
    let tmp = PathBuf::from("tmp");
    let run_dir = tmp.join(run_hash);
    if !run_dir.exists() {
        fs::create_dir_all(&run_dir).unwrap();

        for file in lesson_files.files.iter() {
            let path = run_dir.join(&file.filename);
            fs::write(path, file.content.clone()).unwrap();
        }
    }
    let file = lesson_files.files.iter().find(|f| f.filename == path);


    match file {
        Some(file) => {
            let content_type : mime::Mime = 
                if let Some(extension) = PathBuf::from(&file.filename).extension() {
                    match extension.to_string_lossy().to_string().as_str() {
                        "html" => mime::TEXT_HTML_UTF_8,
                        "css" => mime::TEXT_CSS_UTF_8,
                        _ => mime::TEXT_PLAIN
                    }
                } else {
                    mime::TEXT_PLAIN
                };
            let content_type_str = content_type.to_string();
            ( StatusCode::OK,
            [(CONTENT_TYPE, content_type_str)],
            fs::read_to_string(run_dir.join(&file.filename)).unwrap()
            )
            }
        ,
        None => (
            StatusCode::NOT_FOUND,
            [(CONTENT_TYPE, mime::TEXT_PLAIN.to_string())],
            "Not found".to_string(),
        )
    }
}
