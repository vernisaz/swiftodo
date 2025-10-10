# Simple task manager

## Purpose
The project demonstrates of a possibility using CGI for Swift programs with 
the Rust [web server](https://github.com/vernisaz/simhttp).

## Build
The build is managed by [RustBee](https://github.com/vernisaz/rust_bee).

## Deployment
The following fragment has to be added in **SimHTTP** *conf* file:
```json
{"path":"/task/bin", "_comment_": "Tasks planner in Swift",
       "CGI": true,
       "translated": "./../switodo"},
       {"path":"/task",
       "translated": "./../switodo/html"}
```
Correct the translated paths accordingly the repository location
relative to *SimHTTP* location. Paths can be specified in an absolute form too.

## Status
It's POC, but can be converted to a real project in future.

## To do
Currently, it's unclear how to encode string for JSON values. Is it something like:
```Swift
var container = encoder.singleValueContainer()
let encodedString = try container.encode(string)
```
?