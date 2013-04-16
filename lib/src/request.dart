library request;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:json';
import 'dart:uri';
import 'utils.dart';

// TODO Review all code
// TODO Implement cookies
class RoutingRequest {
  Request request;
  List<String> routeSteps;
  List<String> keys = [];

  RoutingRequest (HttpRequest httpRequest) :
    this.request = new Request(httpRequest),
    this.routeSteps = createRouteSteps(httpRequest.uri.path);
}

class Request {
  HttpRequest httpRequest;
  Map<String, String> keys = new Map<String, String>();
  Response response;
  HashMap get params => httpRequest.queryParameters;
  bool get isForwarded => httpRequest.headers['x-forwarded-host'] != null;
  Uri get uri => httpRequest.uri;
  String get path => uri.path;
  String get method => httpRequest.method;

  Request (httpRequest) : this.httpRequest = httpRequest, this.response = new Response(httpRequest.response);

  header(String name, [value]) {
    var header;
    if (value == null) {
      header = httpRequest.headers[name];

      if (header == null) {
        header = keys[name];
      }

      return header;
    }

    keys[name] = value;
    return this;
  }

  bool accepts(String type) =>
      httpRequest.headers['accept'].any((name) => name.split(',').indexOf(type) > -1 );

  bool isMime(String type) =>
      httpRequest.headers['content-type'].where((value) => value == type).length > 0;
}

class Response {
  HttpResponse httpResponse;
  int get status => httpResponse.statusCode;
  set status (code) => httpResponse.statusCode = code;

  Response (this.httpResponse);

  header(String name, [value]) {
    if (value == null) {
      return httpResponse.headers[name];
    }

    httpResponse.headers.set(name, value);
    return this;
  }

  Response get (String name) => header(name);

  Response set (name, value) => header(name, value);

  Response get type => get('Content-type');
           set type (contentType) => set('Content-Type', contentType);

  Response cache(String cacheType, [Map options]) {
    if(options == null) {
      options = {};
    }
    StringBuffer value = new StringBuffer(cacheType);
    options.forEach((key, val) {
      value.write(', ${key}=${val}');
    });
    return set('Cache-Control', value.toString());
  }

  // TODO Cookie sugary. Issue #3

  send (String string) {
    httpResponse.write(string);
    httpResponse.close();
  }

  sendFile (path) {
    var file = new File(path);
    file.exists().then((found) {
      if (found) {
        httpResponse.addStream(file.openRead());
      } else {
        httpResponse.statusCode = HttpStatus.NOT_FOUND;
        httpResponse.close();
      }
    });
  }

  json (Map data) {
    send(stringify(data));
  }

  redirect (url, [int code = 302]) {
    httpResponse.statusCode = code;
    header('Location', url);
  }

  close () => httpResponse.close();

}

// TODO Implement middlewares. Issue #4
class Middleware {

}