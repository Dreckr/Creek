part of route;

class _Router implements Router {
  RouterConfiguration configuration;
  Route rootRoute;
  
  _Router () {
    this.configuration = new RouterConfiguration();
    this.rootRoute = new Route.withConfiguration(this.configuration, RouteType.STRICT, new Uri());
  }
  
  _Router.withConfiguration (RouterConfiguration this.configuration) {
    this.rootRoute = new Route.withConfiguration(this.configuration, RouteType.STRICT, new Uri());
  }
  
  Route findRoute (Uri uri) {
    var route = this.rootRoute;
    var pathSegments = uri.pathSegments;
    var segmentIndex = 0;
    var segment;
    var routeType;
    var found;
    
    while (pathSegments.length > segmentIndex) {
      segment = pathSegments[segmentIndex];
      

      if (this.configuration.genericPathIdentifiers.any((identifier) => segment.startsWith(identifier))) {
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
        var childRoute = new Route.withConfiguration(
                                      this.configuration, 
                                      routeType, 
                                      copyUri(uri, untilPathSegment: segment));
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
    var segmentIndex = 0;
    var segment;
    var strictChild;
    var genericChild;
    
    while (segmentIndex < pathSegments.length) {
      segment = pathSegments[segmentIndex];
      
      strictChild = null;
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
      route.add(httpRequest);
      return true;
    } else {
      return false;
    }
  }
}

class _Route extends Stream implements Route {
  RouterConfiguration configuration;
  RouteType _type;
  RouteType get type => this._type;
  List<_Route> _children = [];
  List<Route> get children => this._children;
  StreamController _controller;
  Stream _stream;
  bool get isClosed => this._controller == null || this._controller.isClosed;
  bool get isPaused => this.isClosed || this._controller.isPaused || !this._controller.hasListener;
  Uri _uri;
  Uri get uri => this._uri;

  _Route (this._type, this._uri) {
    this.configuration = new RouterConfiguration();
    this._controller = new StreamController<HttpRequest>();
    this._stream = this._controller.stream;
  }
  
  _Route.withConfiguration (this.configuration, this._type, this._uri) {
    this._controller = new StreamController<HttpRequest>();
    this._stream = this._controller.stream;
  }
  
  void add (event) => this._controller.add(event);
  
  void addError (errorEvent) => this._controller.addError(errorEvent);
  
  StreamSubscription listen(void onData(value),
      { void onError(error),
        void onDone(),
        bool cancelOnError }) {
    return this._stream.listen(onData, onError: onError, onDone: onDone,
                          cancelOnError: cancelOnError);
  }
  
  Stream transform (StreamTransformer streamTransformer) {
    if (streamTransformer is CreekContextTransformer) {
      this._stream = streamTransformer.bind(this._stream.transform(new ContextHandler(this)));
    } else {
      this._stream = streamTransformer.bind(this._stream);
    }
    
    return this;
  }

  void close ()  {
    if (this._controller != null)
      this._controller.close();

    for (Route child in children)
      child.close();
  }

}
