library route;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'request.dart';

part 'route_impl.dart';

// TODO Provide statatistic data as: createdAt, timesCalled....
abstract class RouteNode {
  RouteType type;
  List<RouteNode> children;
  List<Middleware> middlewares;
  List<String> keysNames;
  RouteNode fatherNode;
  RouteStreamController controller;
  String stepName;
  bool get isClosed;

  factory RouteNode (RouteType type, RouteNode fatherNode, String route) =>
      new _RouteNode(type, fatherNode, route);

  RouteNode findNode (List<String> routeSteps);

  bool routeRequest (RoutingRequest routingRequest);

  openStream ();

  close (bool closeChildren);

}

class RouteType {
  static final RouteType STRICT = new RouteType._(0);
  static final RouteType KEY = new RouteType._(1);
  static final RouteType GENERIC = new RouteType._(2);

  int value;

  RouteType._(this.value);
}

typedef void PauseStateChangeHandler ();
typedef void SubscriptionStateChangeHandler ();
abstract class RouteStreamController implements StreamController<Request> {
  RouteStream get stream;

  factory RouteStreamController ({onPauseStateChange, onSubscriptionStateChange}) =>
      new _RouteStreamControllerImpl(onPauseStateChange, onSubscriptionStateChange);

  bool add (Request request);
}

abstract class RouteStreamSink implements EventSink<Request> {
  RouteStream _stream;

  factory RouteStreamSink (RouteStream stream) => new _RouteStreamSinkImpl(stream);

  bool add (Request request);

}

abstract class RouteStream implements Stream<Request> {
  bool get isClosed;
  bool get isPaused;
  bool get hasSubscribers;
  RouteStreamSubscription subscription;
  PauseStateChangeHandler _pauseHandler;
  SubscriptionStateChangeHandler _subscriptionHandler;

  factory RouteStream () => new _RouteStreamImpl();

  RouteStreamSubscription treat (void onData(Request request, Response response),
                                 { void onError(AsyncError error),
                                    void onDone(),
                                    bool unsubscribeOnError});

  bool _add (Request request);

  _addError (AsyncError error);

  _close ();

}

abstract class RouteStreamSubscription extends StreamSubscription<Request> {
  RouteStream stream;
  bool get isPaused;
  bool unsubscribeOnError;
  Function dataHandler;
  Function doneHandler;
  Function errorHandler;

  factory RouteStreamSubscription (RouteStream stream,
                                          void onData(Request data),
                                      {   void onError(AsyncError error),
                                          void onDone(),
                                          bool unsubscribeOnError : true}) =>
    new _RouteStreamSubscription(stream, onData, onError, onDone, unsubscribeOnError);

  cancel ();

  onData (void handleData(Request data));

  onError (void handleError(AsyncError error));

  onDone (void handleDone());

  bool handleData (Request request);

  handleError (AsyncError error);

  handleDone ();

  pause ([Future resumeSignal]);

  resume ();
}

