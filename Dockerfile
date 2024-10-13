FROM rust:1.72-slim-bookworm as cargo-build
RUN apt-get update
RUN apt-get install -y build-essential libssl-dev pkg-config npm
WORKDIR /build

RUN mkdir src/ && echo 'fn main() { panic!("Dummy Image Called!")}' > ./src/main.rs
COPY ["Cargo.toml", "Cargo.lock", "package.json", "package-lock.json", "./"]
RUN cargo build --release
COPY ["package.json", "package-lock.json", "./"]
RUN npm install

COPY . .
#need to break the cargo cache
RUN touch ./src/main.rs
RUN cargo build --release
RUN cd client && npx elm make src/Main.elm --output=../www/assets/main.js --optimize

# copies and renames the executable to service
RUN find target -maxdepth 2 -type f -perm -111 -exec cp {} /build/service \; 


# Let's try to save some space
RUN rm -rf /build/target
## Runtime image
FROM rust:1.72-slim-bookworm as runtime
RUN apt-get update
RUN apt-get install -y npm

COPY --from=cargo-build /build/service /app/service
COPY --from=cargo-build /build/secrets.etoml /app/secrets.etoml
COPY --from=cargo-build /build/www /app/www
COPY --from=cargo-build /build/node_modules /app/node_modules
COPY --from=cargo-build /build/.htmlvalidate.json /app/
COPY --from=cargo-build /build/.stylelintrc.json /app/

WORKDIR /app

EXPOSE 8080

CMD ["/app/service"]
