part of server;

class _RouteServerImpl implements RouteServer {
  HttpServer _httpServer;
  RouteNode _deleteTree = new RouteNode(RouteType.STRICT, null, '');
  RouteNode _getTree = new RouteNode(RouteType.STRICT, null, '');
  RouteNode _postTree = new RouteNode(RouteType.STRICT, null, '');
  RouteNode _putTree = new RouteNode(RouteType.STRICT, null, '');
  Function _notFoundHandler;
  bool _running = false;
  bool get isRunning => this._running;
  String address;
  int port;
  int backlog;

  _RouteServerImpl (this.address, this.port, this.backlog);

  RouteStream delete (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._deleteTree, path, handler);

  RouteStream get (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._getTree, path, handler);

  RouteStream post (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._postTree, path, handler);

  RouteStream put (String path, [void handler (Request req, Response res)]) =>
      this._fetchRoute(this._putTree, path, handler);

  notFound (void notFoundHandler (Request request, Response response)) {
    this._notFoundHandler = notFoundHandler;
  }

  Stream<Request> _fetchRoute (RouteNode routeTree, String path, [void handler (Request req, Response res)]) {
    List<String> routeSteps = createRouteSteps(path);
    RouteNode node = routeTree.findNode(routeSteps);
    if (node.isClosed)
      node.openStream();

    if (handler != null)
      node.controller.stream.listen((request) => handler(request, request.response));

    return node.controller.stream;
  }

  route (HttpRequest httpRequest) {
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
      if (this._notFoundHandler == null) {
        Response res = routingRequest.request.response;
        res.status = HttpStatus.NOT_FOUND;
        res.close();
      } else {
        this._notFoundHandler(routingRequest.request, routingRequest.request.response);
      }
    }
  }

  Future<RouteServer> run () {
    Completer completer = new Completer();
    HttpServer.bind(this.address, this.port, this.backlog).then(
        (server) {
          this._running = true;
          this._httpServer = server;
          this._httpServer.listen((HttpRequest request) => this.route(request));
          completer.complete(this);
        },
        onError:
        (exception) {
          completer.completeError(exception);
        });
    return completer.future;
  }

  close () {
    if (this.isRunning)
      this._httpServer.close();

    this._deleteTree.close(true);
    this._getTree.close(true);
    this._postTree.close(true);
    this._putTree.close(true);
    this._running = false;
  }

}
