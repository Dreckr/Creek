part of server;

class _RouteServerImpl implements RouteServer {
  HttpServer httpServer;
  RouteNode _deleteTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _getTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _postTree = new RouteNode(RouteNodeType.STRICT, '');
  RouteNode _putTree = new RouteNode(RouteNodeType.STRICT, '');
  NotFoundHandler notFoundHandler;
  bool _running = false;
  bool get isRunning => this._running;
  String address;
  int port;
  int backlog;

  _RouteServerImpl (this.address, this.port, this.backlog);

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

  Future<RouteServer> run () {
    Completer completer = new Completer();
    HttpServer.bind(this.address, this.port, this.backlog).then(
        (server) {
          this._running = true;
          this.httpServer = server;
          this.httpServer.listen((HttpRequest request) => this.route(request));
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
      this.httpServer.close();

    this._deleteTree.closeStream(true);
    this._getTree.closeStream(true);
    this._postTree.closeStream(true);
    this._putTree.closeStream(true);
    this._running = false;
  }

}
