# A tour of elm

This is the repository of the code running https://a-tour-of-elm.axelerator.de

Heavily inspired by ["a tour of Go"](https://go.dev/tour/welcome/1) it strives to be an interactive, entertaining introduction to
writing web applications with Elm.

# System architecture

The backend is a small Rust web server. For the Elm exercises it will invoke the Elm compiler, so it has to be installed before running the server.
The frontend is of course an Elm application located in the [client](./client) folder.

The Rust server serves content from the [www](./www) folder which contains static content as well as the compiled Elm application.
To build the Elm app in the right location build the `main.js` in the client folder. 

```
$ cd client
$ elm make src/Main.elm --output=main.js
```
