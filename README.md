# elm-format as a service

```
yarn
yarn run dev
```

Then point your browser at <http://localhost:8080>.


## How does this work?

This creates a small express.js server that calls `elm-format` directly and returns the result. It's got a handful of API methods. 

### GET /

Serves the index.html built from `Main.elm`.

### POST /

Formats the posted body with `elm-format` and returns the result.

* **200 OK**: Formatted code is returned as the body
* **400 BAD REQUEST**: Syntax error, elm-format was unable to parse the code, the body will contain the error.
* **500 INTERNAL SERVER ERROR**: Any other problem with elm-format, the server will log the error to the console.

### POST /validate

Asks `elm-format` to validate the given code.

* **200 OK**: Code given is formatted well, there is no body in the response.
* **400 BAD REQUEST**: Either the code is not well formatted or there is a syntax error. The body contains a brief explanation of the problem.
* **500 INTERNAL SERVER ERROR**: Any other problem with elm-format, the server will log the error to the console.
