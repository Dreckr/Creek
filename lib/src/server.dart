library server;

import 'utils.dart';
import 'route.dart';
import 'request.dart';
import 'dart:async';
import 'dart:io';

part 'server_impl.dart';

typedef void NotFoundHandler (Request request, Response response);

/**
 * A [HttpServer] wrapper that routes request.
 *
 * This wrapper allows you to specify routes and handlers for this routes before the server is even created. All the
 * routes are stored to be used later, when the server is running.
 *
 * It can be used as the following code:
 *
 *     Creek server = new Creek('127.0.0.1', 7070, 0);
 *     server
 *       ..get('/foo').listen((Request req) => req.response.send('Hello, Creek!'))
 *       ..post('/bar', (Request req, Response res) => res.send('Hello, Dartisans!'));
 *
 *     server.run().then((Creek srv) => print('Creek is running!'));
 *
 */
abstract class Creek {
  HttpServer httpServer;
  String address;
  int port;
  int backlog;
  bool get isRunning;
  NotFoundHandler notFoundHandler;

  factory Creek ([String address = '127.0.0.1', int port = 0, int backlog = 0]) =>
      new _CreekImpl(address, port, backlog);

  /**
   * Creates a new DELETE route and returns it's [RouteStream].
   *
   * Creates a new DELETE route and returns it's [RouteStream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  delete (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new GET route and returns it's [RouteStream].
   *
   * Creates a new GET route and returns it's [RouteStream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [RouteStreamSubscription] will be returned instead.
   */
  get (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new POST route and returns it's [RouteStream].
   *
   * Creates a new POST route and returns it's [RouteStream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [RouteStreamSubscription] will be returned instead.
   */
  post (String path, [void handler (Request req, Response res)]);

  /**
   * Creates a new PUT route and returns it's [RouteStream].
   *
   * Creates a new PUT route and returns it's [RouteStream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [RouteStreamSubscription] will be returned instead.
   */
  put (String path, [void handler (Request req, Response res)]);

  /**
   * Takes a request and treats it with a defined handler.
   */
  void route (HttpRequest httpRequest);

  /**
   * Creates a [HttpServer] by listening to the specified address and port.
   */
  Future<Creek> run ();

  /**
   * Closes the [HttpServer] and closes all routes.
   */
  close ();

}

