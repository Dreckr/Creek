library server;

import 'utils.dart';
import 'route.dart';
import 'request.dart';
import 'dart:async';
import 'dart:io';

part 'server_impl.dart';

typedef void NotFoundHandler (Request request, Response response);

/**
 * A HTTP server wrapper that routes request.
 *
 * This wrapper allows you to specify routes and handlers for this routes before the server is even created. All the
 * routes are stored to be used later, when the server is running.
 *
 * It can be used as the following code:
 *
 *     RouteServer server = new RouteServer('127.0.0.1', 7070, 0);
 *     server
 *       ..get('/foo').listen((Request req) => req.response.send('Hello, Route!'))
 *       ..post('/bar', (Request req, Response res) => res.send('Hello, Dartisans!'));
 *
 *     server.run().then((RouteServer srv) => print('Route is running!'));
 *
 */
abstract class RouteServer {
  HttpServer httpServer;
  String address;
  int port;
  int backlog;
  bool get isRunning;
  NotFoundHandler notFoundHandler;

  factory RouteServer ([String address = '127.0.0.1', int port = 0, int backlog = 0]) =>
      new _RouteServerImpl(address, port, backlog);

  /**
   * Creates a new DELETE route and returns it's stream.
   *
   * Creates a new DELETE route and returns it's stream. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  delete (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new GET route and returns it's stream.
   *
   * Creates a new GET route and returns it's stream. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  get (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new POST route and returns it's stream.
   *
   * Creates a new POST route and returns it's stream. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  post (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new PUT route and returns it's stream.
   *
   * Creates a new PUT route and returns it's stream. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  put (String path, [void handler (Request req, Response res)]);

  /**
   * Takes a request and treats it with a defined handler.
   */
  void route (HttpRequest httpRequest);

  /**
   * Creates a HTTP server by listening to the specified address and port.
   */
  Future<RouteServer> run ();

  /**
   * Closes the HTTP server and closes all routes.
   */
  close ();

}

