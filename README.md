Route
=====
[![Build Status](https://drone.io/github.com/Dreckr/Route/status.png)](https://drone.io/github.com/Dreckr/Route/latest)

A simple web development framework with Sinatra looks and Dart power.

Route is a web development framework that let's you feel at home while you take advantage of Dart. It does
things a little different than most Sinatra-inspired frameworks by using a routing tree (instead of a set of RegExp
matchers) and Streams API.

A routing tree is a tree with all the accessible URL paths of a server. This tree allows the framework to be lighting 
fast while finding the right handler of a HTTP request. Also, it stores some metadata about your routes that might
come in handy. For example, when close a route (e.g., "/foo"), you might want to close all it's child routes (e.g., 
"/foo/bar", "/foo/barz", "/foo/bar/qux") and Route can do exactly that.

With the use of the Streams API, you get full control of your request flow. You can filter requests by calling 
Stream.where, redirect requests internally to another consumer with Stream.pipe, modify request in some manner using
a StreamTransformer, pause your handler from receiving request through StreamSubscription.pause... If Dart's HttpServer 
is a Stream, your framework should work accordingly to give as much power as possible.

Usage
-----
Running a Route server is really straigth forward:

```dart
RouteServer server = new RouteServer('127.0.0.1', 7070);
server.run();
```

When a RouteServer is instanciated, it stores the address and the port passed. // TODO continue...

Routes
------

// TODO Issue #6
// Mention route tree

RouteStreams and RouteStreamSubscriptions
------------------------------------------

// TODO Issue #6
// Present stream features and why they might be interesting

License
-------

Copyright (c) 2013 Diego Rocha <diego.rocha.comp@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
