library server;

import 'utils.dart';
import 'route.dart';
import 'request.dart';
import 'dart:async';
import 'dart:io';

part 'server_impl.dart';

typedef void NotFoundHandler (HttpRequest request, HttpResponse response);

/**
 * A lightweight framework that routes HttpRequests and provides easier handling.
 *
 * This framework allows you to specify routes and handlers before a server is even created. All the
 * routes are stored to be used later, when the server is binded.
 *
 * It can be used as the following code:
 *
 *     Creek creek = new Creek();
 *     creek
 *       ..get('/foo').listen((HttpRequest req) => req.response.send('Hello, Creek!'))
 *       ..post('/bar', (HttpRequest req, HttpResponse res) => res.send('Hello, Dartisans!'));
 *
 *     creek.bind('127.0.0.1', 7070).then((HttpServer server) => print('Creek is running!'));
 *
 * In this case, an address and a port is passed to the bind() method, so Creek will create its own HttpServer and
 * will subscribe to it. If an existing HttpServer was passed to this method, Creek would listen on it.
 *
 * It is possible to bind the same Creek to several servers by simply calling bind() multiple time with different
 * arguments.
 */
abstract class Creek {
  /// Handler used when there is no route for a HttpRequest
  NotFoundHandler notFoundHandler;

  /// All subscriptions to HttpServers
  List<HttpServerSubscription> serverSubscriptions;

  factory Creek () =>
      new _CreekImpl();

  /**
   * Creates a new DELETE route and returns it's [Stream].
   *
   * Creates a new DELETE route and returns it's [Stream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and the subscription will be returned instead.
   */
  delete (String path, [void handler (HttpRequest req, HttpResponse res)]);

  /**
   * Creates a new GET route and returns it's [Stream].
   *
   * Creates a new GET route and returns it's [Stream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [RouteStreamSubscription] will be returned instead.
   */
  get (String path, [void handler (HttpRequest req, HttpResponse res)]);

  /**
   * Creates a new POST route and returns it's [Stream].
   *
   * Creates a new POST route and returns it's [Stream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [StreamSubscription] will be returned instead.
   */
  post (String path, [void handler (HttpRequest req, HttpResponse res)]);

  /**
   * Creates a new PUT route and returns it's [Stream].
   *
   * Creates a new PUT route and returns it's [Stream]. An optional handler may be passed. If this handler is passed,
   * it will be used to listen to the stream and a [StreamSubscription] will be returned instead.
   */
  put (String path, [void handler (HttpRequest req, HttpResponse res)]);

  /**
   * Takes a request and treats it with a defined handler.
   */
  void route (HttpRequest httpRequest);

  /**
   * Creates a [HttpServer] by listening to the specified address and port.
   */
  Future<HttpServerSubscription> bind ([serverOrAddress, port, backlog]);

  void onError (void onErrorHandler (error));

  void onDone (void onDoneHandler ());

  /**
   * Closes all HttpServers subscriptions and closes all routes.
   */
  close ();

}

/**
 * A StreamSubscription wrapper that keeps a reference to the server.
 */
class HttpServerSubscription implements StreamSubscription<HttpRequest> {
  StreamSubscription<HttpRequest> _subscription;
  HttpServer server;

  HttpServerSubscription._(this._subscription, this.server);

  void cancel () => this._subscription.cancel();

  void onData(handleData) => this._subscription.onData(handleData);

  void onDone(handleDone) => this._subscription.onDone(handleDone);

  void onError(handleError) => this._subscription.onError(handleError);

  void pause([resumeSignal]) => this._subscription.pause(resumeSignal);

  void resume() => this._subscription.resume();

  Future asFuture([futureValue]) => this._subscription.asFuture(futureValue);
}

