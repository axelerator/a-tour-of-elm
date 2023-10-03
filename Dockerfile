FROM rust:1.72-slim-bookworm

WORKDIR /app

RUN apt-get update
RUN apt-get install -y build-essential libssl-dev pkg-config npm

RUN mkdir src/ && echo 'fn main() { panic!("Dummy Image Called!")}' > ./src/main.rs
COPY ["Cargo.toml", "Cargo.lock", "package.json", "package-lock.json", "./"]
RUN cargo build --release
COPY ["package.json", "package-lock.json", "./"]
RUN npm install

COPY . .
#need to break the cargo cache
RUN touch ./src/main.rs
RUN cargo build --release

RUN cd client && npx elm make src/Main.elm --output=main.js --optimize

EXPOSE 8080

CMD ["/app/target/release/a-tour-of-elm"]
