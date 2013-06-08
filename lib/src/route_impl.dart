part of route;

class _RouteNode implements RouteNode {
  RouteNodeType _type;
  RouteNodeType get type => this._type;
  List<_RouteNode> _children = [];
  List<RouteNode> get children => this._controller;
  StreamController _controller;
  StreamController get controller => this._controller;
  bool get isClosed => controller == null || controller.isClosed;
  bool get isPaused => this.isClosed || controller.isPaused || !controller.hasListener;
  Uri _uri;
  Uri get uri => this._uri;

  _RouteNode (this._type, this._uri);

  RouteNode findNode (Uri uri) {
    return this._findNode(uri);
  }
  
  RouteNode _findNode (Uri uri, [segmentIndex = 1]) {
    var pathSegments = uri.pathSegments;
    
    if (pathSegments.length == segmentIndex) {
      return this;
    }

    var segment = pathSegments[segmentIndex];
    var routeType;

    if (segment.startsWith('*') ||segment.startsWith(':')) {
      routeType = RouteNodeType.GENERIC;
    } else {
      routeType = RouteNodeType.STRICT;
    }

    for (var child in this.children)
      if ((routeType == RouteNodeType.STRICT && child.uri.pathSegments.last == segment) ||
          (child.type == routeType && routeType != RouteNodeType.STRICT))
        return child._findNode(uri, segmentIndex + 1);

    var childNode = new _RouteNode(routeType, copyUri(uri, untilPathSegment: segment));
    this.children.add(childNode);
    return childNode._findNode(uri, segmentIndex + 1);
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
      } else if (child.type == RouteNodeType.GENERIC && strictChild == null) {
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
      for (RouteNode child in children)
        child.closeStream(true);
  }

}