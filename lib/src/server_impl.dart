part of server;

class _CreekImpl implements Creek {
  RouteNode _deleteTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _getTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _postTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _putTree = new RouteNode(RouteNodeType.STRICT, '');
  NotFoundHandler notFoundHandler;
  List<HttpServerSubscription> serverSubscriptions = [];
  var _onErrorHandler;
  var _onDoneHandler;

  _CreekImpl ();

  delete (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._deleteTree, path, handler);

  get (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._getTree, path, handler);

  post (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._postTree, path, handler);

  put (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._putTree, path, handler);

  _fetchRoute (RouteNode routeTree, String path, [void handler (Request req, Response res)]) {
    List<String> routeSteps = createRouteSteps(path);
    RouteNode node = routeTree.findNode(routeSteps);
    if (node.isClosed)
      node.openStream();

    if (handler != null) {
      return node.controller.stream.treat(handler);
    }

    return node.controller.stream;
  }

  void route (HttpRequest httpRequest) {
    RoutingRequest routingRequest = new RoutingRequest(httpRequest);
    RouteNode tree;

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
        Response res = routingRequest.request.response;
        res.status = HttpStatus.METHOD_NOT_ALLOWED;
        res.close();
        return;
    }

    if (!tree.routeRequest(routingRequest)) {
      if (this.notFoundHandler == null) {
        Response res = routingRequest.request.response;
        res.status = HttpStatus.NOT_FOUND;
        res.close();
      } else {
        this.notFoundHandler(routingRequest.request, routingRequest.request.response);
      }
    }
  }

  Future<HttpServerSubscription> bind ([serverOrAddress, port = 0, backlog = 0]) {
    Completer<HttpServerSubscription> completer = new Completer<HttpServerSubscription>();
    if (serverOrAddress is HttpServer) {
      completer.complete(this._bind(serverOrAddress));
    } else {
      HttpServer.bind(serverOrAddress, port, backlog).then(
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
