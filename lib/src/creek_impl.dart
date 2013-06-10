part of creek;

class _Creek implements Creek {
  RouterConfiguration configuration = new RouterConfiguration();
  
  Router _deleteRouter;
  Router _getRouter;
  Router _postRouter;
  Router _putRouter;
  
  NotFoundHandler notFoundHandler;
  List<HttpServerSubscription> serverSubscriptions = [];
  var _onErrorHandler;
  var _onDoneHandler;

  _Creek () {
    this._deleteRouter = new Router.withConfiguration(configuration);
    this._getRouter = new Router.withConfiguration(configuration);
    this._postRouter = new Router.withConfiguration(configuration);
    this._putRouter = new Router.withConfiguration(configuration);
  }

  delete (dynamic path) =>
      this._fetchRoute(this._deleteRouter, path);

  get (dynamic path) =>
      this._fetchRoute(this._getRouter, path);

  post (dynamic path) =>
      this._fetchRoute(this._postRouter, path);

  put (dynamic path) =>
      this._fetchRoute(this._putRouter, path);

  Route _fetchRoute (Router router, dynamic path) {
    var uri;
    
    if (path is Uri)
      uri = path;
    else if (path is String)
      uri = Uri.parse(path);
    else
      throw new Exception('$path is of type ${path.runtimeType} when String or Uri were expected');
    
    var route = router.findRoute(uri);

    return route;
  }

  void route (HttpRequest httpRequest) {
    HttpResponse httpResponse = httpRequest.response;
    Router router;

    switch (httpRequest.method) {
      case 'DELETE':
        router = this._deleteRouter;
        break;
      case 'GET':
        router = this._getRouter;
        break;
      case 'POST':
        router = this._postRouter;
        break;
      case 'PUT':
        router = this._putRouter;
        break;
      default:
        httpResponse.statusCode = HttpStatus.NOT_FOUND;
        httpResponse.close();
        return;
    }

    if (!router.routeRequest(httpRequest)) {
      if (this.notFoundHandler == null) {
        httpResponse.statusCode = HttpStatus.NOT_FOUND;
        httpResponse.close();
      } else {
        this.notFoundHandler(httpRequest);
      }
    }
  }

  Future<HttpServerSubscription> bind ({HttpServer server, String address, int port: 0, int backlog: 0}) {
    if (server == null && address == null)
      throw new Exception('No HttpServer or Address specified. Please set one of this arguments.');
    else if (server != null && address != null)
      throw new Exception('HttpServer and Address specified. Please set only one of this arguments.');
    
    Completer<HttpServerSubscription> completer = new Completer<HttpServerSubscription>();
    if (server != null) {
      completer.complete(this._bind(server));
    } else {
      HttpServer.bind(address, port, backlog: backlog).then(
          (HttpServer _server) => completer.complete(this._bind(_server)),
          onError: (error) => completer.completeError(error)
      );

    }
    return completer.future;
  }

  HttpServerSubscription _bind (HttpServer server) {
    StreamSubscription<HttpRequest> streamSubscription = server.listen(
        (HttpRequest httpRequest) => this.route(httpRequest),
        onError: this._onError,
        onDone: this._onDone);

    HttpServerSubscription subscription = new HttpServerSubscription._(streamSubscription, server);
    this.serverSubscriptions.add(subscription);

    return subscription;
  }

  void onError (void onErrorHandler (error)) {
    this._onErrorHandler = onErrorHandler;
  }

  _onError (error) {
    if (this._onErrorHandler != null)
      this._onErrorHandler(error);
  }

  void onDone (void onDoneHandler ()) {
    this._onDoneHandler = onDoneHandler;
  }

  _onDone () {
    if (this._onDoneHandler != null)
      this._onDoneHandler();
  }

  close () {
    this._deleteRouter.rootRoute.close();
    this._getRouter.rootRoute.close();
    this._postRouter.rootRoute.close();
    this._putRouter.rootRoute.close();

    for (StreamSubscription<HttpRequest> subs in this.serverSubscriptions)
      subs.cancel();
  }

}
