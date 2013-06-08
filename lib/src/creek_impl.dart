part of server;

class _Creek implements Creek {
  Route _deleteTree = new Route(RouteType.STRICT, new Uri());
  Route _getTree = new Route(RouteType.STRICT, new Uri());
  Route _postTree = new Route(RouteType.STRICT, new Uri());
  Route _putTree = new Route(RouteType.STRICT, new Uri());
  NotFoundHandler notFoundHandler;
  List<HttpServerSubscription> serverSubscriptions = [];
  var _onErrorHandler;
  var _onDoneHandler;

  _Creek ();

  delete (path) =>
      this._fetchRoute(this._deleteTree, path);

  get (path) =>
      this._fetchRoute(this._getTree, path);

  post (path) =>
      this._fetchRoute(this._postTree, path);

  put (path) =>
      this._fetchRoute(this._putTree, path);

  Stream _fetchRoute (Route routeTree, path) {
    var uri;
    
    if (path is Uri)
      uri = path;
    else if (path is String)
      uri = Uri.parse(path);
    else
      throw new Exception('$path is of type ${path.runtimeType} when String or Uri were expected');
    
    Route node = routeTree.findRoute(uri);
    if (node.isClosed)
      node.openStream();

    return node.controller.stream;
  }

  void route (HttpRequest httpRequest) {
    HttpResponse httpResponse = httpRequest.response;
    Route tree;

    switch (httpRequest.method) {
      case 'DELETE':
        tree = this._deleteTree;
        break;
      case 'GET':
        tree = this._getTree;
        break;
      case 'POST':
        tree = this._postTree;
        break;
      case 'PUT':
        tree = this._putTree;
        break;
      default:
        httpResponse.statusCode = HttpStatus.NOT_FOUND;
        httpResponse.close();
        return;
    }

    if (!tree.routeRequest(httpRequest)) {
      if (this.notFoundHandler == null) {
        httpResponse.statusCode = HttpStatus.NOT_FOUND;
        httpResponse.close();
      } else {
        this.notFoundHandler(httpRequest);
      }
    }
  }

  Future<HttpServerSubscription> bind ([serverOrAddress, port = 0, backlog = 0]) {
    Completer<HttpServerSubscription> completer = new Completer<HttpServerSubscription>();
    if (serverOrAddress is HttpServer) {
      completer.complete(this._bind(serverOrAddress));
    } else {
      HttpServer.bind(serverOrAddress, port, backlog: backlog).then(
          (HttpServer server) => completer.complete(this._bind(server)),
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
    this._deleteTree.closeStream(true);
    this._getTree.closeStream(true);
    this._postTree.closeStream(true);
    this._putTree.closeStream(true);

    for (StreamSubscription<HttpRequest> subs in this.serverSubscriptions)
      subs.cancel();
  }

}
