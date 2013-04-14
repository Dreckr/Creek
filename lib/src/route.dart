library route;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'request.dart';

part 'route_impl.dart';

/**
 * A node that forms routing trees.
 *
 * Each node represents a path in the server. These nodes are defined by splitting
 * the path by slash characters ("/") and creating a node for each part of the path. Here,
 * we call this parts as "steps".
 *
 * A path like "/foo/bar" will have two steps, "foo" and "bar". A node will be created
 * for the "foo" step and it will be a child of the tree's root node. Another node will be created for the "bar" step
 * and this node will be a child of the "foo" node. It is worth noting that a node may have many children.
 *
 * When defining paths, the server creates trees with these node and each node has its own stream of requests.
 * When the server receives a request for a path, it finds is node and if the node's stream has a subscriber, it is
 * feeded with the request. If not, the request is treated with the server's "not found" handler.
 */
abstract class RouteNode {

  /**
   * The type of this node's step.
   *
   * A node may be strict, generic or key. A strict node only matches requests with paths that strictly match its step
   * (the paths are matched step by step). A generic node matches anything to its step. Key nodes also match anything to
   * its step, but is also stores the value matched so it can be used by the request handler.
   */
  RouteNodeType type;

  /// This node's children
  List<RouteNode> children;
  //List<Middleware> middlewares;

  /// Key names associated to this path.
  List<String> keysNames;
  RouteStreamController controller;

  /// This node's step name.
  String stepName;
  bool get isClosed;

  factory RouteNode (RouteNodeType type, String route) =>
      new _RouteNode(type, route);

  /**
   * Returns the node identified by the routeSteps.
   *
   * Searches the tree that has this node as root until it finds the node identified by this steps. If it doesn't find
   * a node identified by this steps, all node necessary to reach it are created.
   */
  RouteNode findNode (List<String> routeSteps);

  /**
   * Passes the request to the appropriate stream and returns true if succeded.
   *
   * Searches the tree that has this node as root to find the node matching the request. If it is found and it's stream
   * has a subscriber, the stream is feeded with the request, returning true. If not, returns false.
   */
  bool routeRequest (RoutingRequest routingRequest);

  /**
   * Opens a new stream.
   *
   * Creates a new [RouteStreamController] if the current is non-existent or is closed.
   */
  void openStream ();


  /**
   * Closes the stream.
   *
   * Closes streamController and, if [closeTree] is true, also closes all of its descendent's streams.
   */
  void closeStream (bool closeTree);

}

/**
 * The type of a [RouteNode].
 *
 * A [RouteNode] may be strict, key or generic. This enum-like class helps guaranties that every [RouteNode] is always
 * one of these.
 */
class RouteNodeType {
  static final RouteNodeType STRICT = new RouteNodeType._(0);
  static final RouteNodeType KEY = new RouteNodeType._(1);
  static final RouteNodeType GENERIC = new RouteNodeType._(2);

  int value;

  RouteNodeType._(this.value);
}

typedef void PauseStateChangeHandler ();
typedef void SubscriptionStateChangeHandler ();

/**
 * A [StreamController] specialized in dealing with requests.
 *
 * A implementation of StreamController built to guarantee proper behavior and provide more specialized functionality.
 */
abstract class RouteStreamController implements StreamController<Request> {
  RouteStream get stream;

  factory RouteStreamController ({onPauseStateChange, onSubscriptionStateChange}) =>
      new _RouteStreamControllerImpl(onPauseStateChange, onSubscriptionStateChange);
}

/**
 * A [EventSink] specialized in dealing with requests.
 *
 * A implementation of EventSink built to guarantee proper behavior and provide more specialized functionality.
 */
abstract class RouteStreamSink implements EventSink<Request> {
  RouteStream _stream;

  factory RouteStreamSink (RouteStream stream) => new _RouteStreamSinkImpl(stream);

}

/**
 * A [Stream] specialized in dealing with requests.
 *
 * A implementation of Stream built to guarantee proper behavior and provide more specialized functionality.
 */
abstract class RouteStream implements Stream<Request> {
  bool get isClosed;
  bool get isPaused;
  bool get hasSubscribers;
  RouteStreamSubscription subscription;
  PauseStateChangeHandler _pauseHandler;
  SubscriptionStateChangeHandler _subscriptionHandler;

  factory RouteStream () => new _RouteStreamImpl();

  /**
   * Creates and returns a subscription to this stream.
   *
   * Creates a subscription by listening to the stream. The onData handler is converted to a single parameter handler.
   */
  RouteStreamSubscription treat (void onData(Request request, Response response),
                                 { void onError(AsyncError error),
                                    void onDone(),
                                    bool unsubscribeOnError});

  void _add (Request request);

  void _addError (AsyncError error);

  void _close ();

}

/**
 * A [StreamSubscription] specialized in dealing with requests.
 *
 * A implementation of StreamSubscription built to guarantee proper behavior and provide more specialized functionality.
 */
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

  void _handleData (Request request);

  void _handleError (AsyncError error);

  void _handleDone ();
}

