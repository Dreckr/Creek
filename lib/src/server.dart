library server;

import 'utils.dart';
import 'route.dart';
import 'request.dart';
import 'dart:async';
import 'dart:io';

part 'server_impl.dart';

abstract class RouteServer {
  String address;
  int port;
  int backlog;
  bool get isRunning;

  factory RouteServer ([String address = '127.0.0.1', int port = 0, int backlog = 0]) =>
      new _RouteServerImpl(address, port, backlog);

  RouteStream delete (String path, [void handler (Request req, Response res)]);

  RouteStream get (String path, [void handler (Request req, Response res)]);

  RouteStream post (String path, [void handler (Request req, Response res)]);

  RouteStream put (String path, [void handler (Request req, Response res)]);

  notFound (void notFoundHandler (Request req, Response res));

  route (HttpRequest httpRequest);

  Future<RouteServer> run ();

  close ();

}

