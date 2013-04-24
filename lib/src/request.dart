library request;

import 'dart:io';
import 'utils.dart';


class RoutingRequest {
  HttpRequest httpRequest;
  List<String> routeSteps;
  List<String> keys = [];

  RoutingRequest (this.httpRequest) {
    this.routeSteps = createRouteSteps(this.httpRequest.uri.path);
  }
}

// TODO Implement middlewares. Issue #4
class Middleware {

}