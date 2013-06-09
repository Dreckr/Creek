part of creek;

class _Creek implements Creek {
  CreekConfiguration configuration = new CreekConfiguration();
  
  Router _deleteRouter;
  Router _getRouter;
  Router _postRouter;
  Router _putRouter;
  
  NotFoundHandler notFoundHandler;
  List<HttpServerSubscription> serverSubscriptions = [];
  var _onErrorHandler;
  var _onDoneHandler;

  _Creek () {
    this._deleteRouter = new Router(this);
    this._getRouter = new Router(this);
    this._postRouter = new Router(this);
    this._putRouter = new Router(this);
  }

  delete (path) =>
      this._fetchRoute(this._deleteRouter, path);

  get (path) =>
      this._fetchRoute(this._getRouter, path);

  post (path) =>
      this._fetchRoute(this._postRouter, path);

  put (path) =>
      this._fetchRoute(this._putRouter, path);

  Stream _fetchRoute (Router router, path) {
    var uri;
    
    if (path is Uri)
      uri = path;
    else if (path is String)
      uri = Uri.parse(path);
    else
      throw new Exception('$path is of type ${path.runtimeType} when String or Uri were expected');
    
    Route node = router.findRoute(uri);
    if (node.isClosed)
      node.openStream();

    return node.controller.stream;
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
    this._deleteRouter.rootRoute.closeStream(true);
    this._getRouter.rootRoute.closeStream(true);
    this._postRouter.rootRoute.closeStream(true);
    this._putRouter.rootRoute.closeStream(true);

    for (StreamSubscription<HttpRequest> subs in this.serverSubscriptions)
      subs.cancel();
  }

}
