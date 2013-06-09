part of route;

class _Router implements Router {
  Creek creek;
  Route rootRoute;
  
  _Router (Creek this.creek) {
    this.rootRoute = new Route(this.creek, RouteType.STRICT, new Uri());
  }
  
  Route findRoute (Uri uri) {
    var route = this.rootRoute;
    var pathSegments = uri.pathSegments;
    var segmentIndex = 1;
    var segment;
    var routeType;
    var found;
    
    while (pathSegments.length > segmentIndex) {
      segment = pathSegments[segmentIndex];
      

      if (this.creek.configuration.genericPathIdentifiers.any((identifier) => segment.startsWith(identifier))) {
        routeType = RouteType.GENERIC;
      } else {
        routeType = RouteType.STRICT;
      }
      
      found = false;
      for (var childRoute in route.children) {
        if ((routeType == RouteType.STRICT && childRoute.uri.pathSegments.last == segment) ||
            (childRoute.type == routeType && routeType != RouteType.STRICT)) {
          route = childRoute;
          found = true;
          break;
        }
      }
      
      if (!found) {
        var childRoute = new _Route(this.creek, routeType, copyUri(uri, untilPathSegment: segment));
        route.children.add(childRoute);
        route = childRoute;
      }
      
      segmentIndex++;
    }
    
    return route;
  }
  
  bool routeRequest (HttpRequest httpRequest) {
    var route = this.rootRoute;
    var pathSegments = httpRequest.uri.pathSegments;
    var segmentIndex = 1;
    var segment;
    var strictChild;
    var genericChild;
    
    while (segmentIndex < pathSegments.length) {
      segment = pathSegments[segmentIndex];
      
      strictChild = null;
      genericChild = null;
      for (var childRoute in route.children) {
        if (childRoute.uri.pathSegments.last == segment) {
          strictChild = childRoute;
        } else if (childRoute.type == RouteType.GENERIC && strictChild == null) {
          genericChild = childRoute;
        }
      }

      if (strictChild != null)
        route = strictChild;
      else if (genericChild != null)
        route = genericChild;
      else
        return false;
      
      segmentIndex++;
    }
    
    if (!route.isClosed && !route.isPaused) {
      route.controller.add(httpRequest);
      return true;
    } else {
      return false;
    }
  }
}

class _Route implements Route {
  Creek creek;
  RouteType _type;
  RouteType get type => this._type;
  List<_Route> _children = [];
  List<Route> get children => this._children;
  StreamController _controller;
  StreamController get controller => this._controller;
  Stream get stream => this._controller.stream;
  bool get isClosed => controller == null || controller.isClosed;
  bool get isPaused => this.isClosed || controller.isPaused || !controller.hasListener;
  Uri _uri;
  Uri get uri => this._uri;

  _Route (this.creek, this._type, this._uri);
  
//  void use (StreamTransformer streamTransformer) {
//    if (streamTransformer is CreekTransformer) {
//      Stream<TransformationContext> transformationStream = this.stream.transform(
//          new StreamTransformer<dynamic, TransformationContext>(
//            handleData: 
//              (request, eventSink) => 
//                eventSink.add(new TransformationContext(this.creek, this, request))));
//      
//      transformationStream.transform(streamTransformer);
//    }
//  }

  void openStream () {
    if (this.isClosed)
      this._controller = new StreamController<HttpRequest>();
  }

  void closeStream (bool closeChildren)  {
    if (this._controller != null)
      this._controller.close();

    if (closeChildren)
      for (Route child in children)
        child.closeStream(true);
  }

}