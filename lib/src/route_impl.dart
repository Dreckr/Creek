part of route;

class _Route implements Route {
  RouteType _type;
  RouteType get type => this._type;
  List<_Route> _children = [];
  List<Route> get children => this._children;
  StreamController _controller;
  StreamController get controller => this._controller;
  bool get isClosed => controller == null || controller.isClosed;
  bool get isPaused => this.isClosed || controller.isPaused || !controller.hasListener;
  Uri _uri;
  Uri get uri => this._uri;

  _Route (this._type, this._uri);

  Route findRoute (Uri uri) {
    return this._findRoute(uri);
  }
  
  Route _findRoute (Uri uri, [segmentIndex = 1]) {
    var pathSegments = uri.pathSegments;
    
    if (pathSegments.length == segmentIndex) {
      return this;
    }

    var segment = pathSegments[segmentIndex];
    var routeType;

    if (segment.startsWith('*') ||segment.startsWith(':')) {
      routeType = RouteType.GENERIC;
    } else {
      routeType = RouteType.STRICT;
    }

    for (var child in this._children)
      if ((routeType == RouteType.STRICT && child.uri.pathSegments.last == segment) ||
          (child.type == routeType && routeType != RouteType.STRICT))
        return child._findRoute(uri, segmentIndex + 1);

    var childNode = new _Route(routeType, copyUri(uri, untilPathSegment: segment));
    this.children.add(childNode);
    return childNode._findRoute(uri, segmentIndex + 1);
  }

  bool routeRequest (HttpRequest httpRequest) {
    return this._routeRequest(httpRequest);    
  }
  
  bool _routeRequest (HttpRequest httpRequest, [segmentIndex = 1]) {
    if (httpRequest.uri.pathSegments.length == segmentIndex) {
      if (!this.isClosed && !this.isPaused) {
        this.controller.add(httpRequest);
        return true;
      } else {
        return false;
      }
    }

    var segment = httpRequest.uri.pathSegments[segmentIndex];
    var strictChild, genericChild;
    for (var child in this.children) {
      if (child.uri.pathSegments.last == segment) {
        strictChild = child;
      } else if (child.type == RouteType.GENERIC && strictChild == null) {
        genericChild = child;
      }
    }

    if (strictChild != null)
      if(strictChild._routeRequest(httpRequest, segmentIndex + 1))
        return true;

    if (genericChild != null)
      return genericChild._routeRequest(httpRequest, segmentIndex + 1);

    return false;
  }

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