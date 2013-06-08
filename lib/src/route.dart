library route;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'utils.dart';

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
abstract class Route {

  /**
   * The type of this node's step.
   *
   * A node may be strict, generic or key. A strict node only matches requests with paths that strictly match its step
   * (the paths are matched step by step). A generic node matches anything to its step. Key nodes also match anything to
   * its step, but is also stores the value matched so it can be used by the request handler.
   */
  RouteType get type;

  /// This node's children
  List<Route> get children;

  StreamController get controller;

  bool get isClosed;
  
  Uri get uri;

  factory Route (RouteType type, Uri uri) =>
      new _Route(type, uri);

  /**
   * Returns the node identified by the routeSteps.
   *
   * Searches the tree that has this node as root until it finds the node identified by this steps. If it doesn't find
   * a node identified by this steps, all node necessary to reach it are created.
   */
  Route findRoute (Uri uri);

  /**
   * Passes the request to the appropriate stream and returns true if succeded.
   *
   * Searches the tree that has this node as root to find the node matching the request. If it is found and it's stream
   * has a subscriber, the stream is feeded with the request, returning true. If not, returns false.
   */
  bool routeRequest (HttpRequest httpRequest);

  /**
   * Opens a new stream.
   *
   * Creates a new [StreamController] if the current is non-existent or is closed.
   */
  void openStream ();


  /**
   * Closes the stream.
   *
   * Closes streamController and, if [closeChildren] is true, also closes all of its descendent's streams.
   */
  void closeStream (bool closeChildren);

}

/**
 * The type of a [RouteNode].
 *
 * A [RouteNode] may be strict, key or generic. This enum-like class helps guaranties that every [RouteNode] is always
 * one of these.
 */
class RouteType {
  static final RouteType STRICT = new RouteType._(0);
  static final RouteType GENERIC = new RouteType._(1);

  int value;

  RouteType._(this.value);
}