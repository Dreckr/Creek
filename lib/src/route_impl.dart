part of route;

class _RouteNode implements RouteNode {
  RouteNodeType type;
  List<RouteNode> children = [];
  //List<Middleware> middlewares = [];
  List<String> keysNames = [];
  RouteStreamController controller;
  String stepName;
  bool get isClosed => controller == null || controller.isClosed;
  bool get isPaused => this.isClosed || controller.isPaused || !controller.hasSubscribers;

  _RouteNode (this.type, this.stepName);

  RouteNode findNode (List<String> routeSteps) {
    return this._findNode(routeSteps, new List.from(this.keysNames));
  }

  RouteNode _findNode (List<String> routeSteps, List<String> keysNames) {
    if (routeSteps.length == 0) {
      this.keysNames = keysNames;
      return this;
    }

    String step = routeSteps.removeAt(0);
    RouteNodeType routeType;

    if (step.startsWith('*')) {
      routeType = RouteNodeType.GENERIC;
    } else if (step.startsWith(':')) {
      routeType = RouteNodeType.KEY;
      step = step.substring(1);
      keysNames.add(step);
    } else {
      routeType = RouteNodeType.STRICT;
    }

    for (var child in this.children)
      if ((routeType == RouteNodeType.STRICT && child.stepName == step) ||
          (child.type == routeType && routeType != RouteNodeType.STRICT))
        return child._findNode(routeSteps, keysNames);

    var childNode = new RouteNode(routeType, step);
    this.children.add(childNode);
    return childNode._findNode(routeSteps, keysNames);
  }

  bool routeRequest (RoutingRequest routingRequest) {
    if (routingRequest.routeSteps.length == 0) {
      if (!this.isClosed && !this.isPaused) {
        this._parseKeys(routingRequest);
        this.controller.add(routingRequest.request);
        return true;
      } else {
        return false;
      }
    }

    String step = routingRequest.routeSteps.removeAt(0);
    RouteNode strictChild, genericChild;
    for (var child in this.children) {
      if (child.stepName == step) {
        strictChild = child;
      } else if (child.type == RouteNodeType.KEY) {
        routingRequest.keys.add(step);
        genericChild = child;
      } else if (child.type == RouteNodeType.GENERIC && strictChild == null) {
        genericChild = child;
      }
    }

    if (strictChild != null)
      if(strictChild.routeRequest(routingRequest))
        return true;

    if (genericChild != null)
      return genericChild.routeRequest(routingRequest);

    return false;
  }

  void openStream () {
    if (this.isClosed)
      this.controller = new RouteStreamController();
  }

  void closeStream (bool closeTree)  {
    if (this.controller != null)
      this.controller.close();

    if (closeTree)
      for (RouteNode child in children)
        child.closeStream(true);
  }

  void _parseKeys (RoutingRequest routingRequest) {
    var i = 0;

    for (String key in routingRequest.keys) {
      routingRequest.request.header(this.keysNames[i], key);
      i++;
    }
  }

}

class _RouteStreamControllerImpl implements RouteStreamController {
  RouteStream get stream => this.sink._stream;
  RouteStreamSink sink;
  bool get isClosed => sink._stream.isClosed;
  bool get isPaused => sink._stream.isPaused;
  bool get hasSubscribers => sink._stream.hasSubscribers;

  _RouteStreamControllerImpl(onPauseStateChange, onSubscriptionStateChange) {
    this.sink = new _RouteStreamSinkImpl(new _RouteStreamImpl());
    this.sink._stream._pauseHandler = onPauseStateChange;
    this.sink._stream._subscriptionHandler = onSubscriptionStateChange;
  }


  void add (Request request) {
    this.sink.add(request);
  }

  void addError (error, [stackTrace]) {
    AsyncError asyncError;
    if (error is AsyncError) {
      asyncError = error;
    } else {
      asyncError = new AsyncError(error, stackTrace);
    }

    this.sink.addError(asyncError);
  }

  void close () {
    if (!this.isClosed)
      this.sink.close();
  }

  void signalError (AsyncError error) {
    this.sink.addError(error);
  }

}

class _RouteStreamSinkImpl implements RouteStreamSink {
  RouteStream _stream;

  _RouteStreamSinkImpl (RouteStream stream) : this._stream = stream;

  void add (Request request) {
    this._stream._add(request);
  }

  void addError (AsyncError error) {
    this._stream._addError(error);
  }

  void close () {
    this._stream._close();
  }

}

class _RouteStreamImpl extends Stream<Request> implements RouteStream {
  bool _closed = false;
  bool get isClosed => this._closed;
  bool get isPaused => this.subscription == null || this.subscription.isPaused;
  bool get hasSubscribers => this.subscription != null;

  RouteStreamSubscription subscription;

  // TODO Use this handlers
  PauseStateChangeHandler _pauseHandler;
  SubscriptionStateChangeHandler _subscriptionHandler;

  RouteStreamSubscription treat (void onData(Request request, Response response),
                                  { void onError(AsyncError error),
                                    void onDone(),
                                    bool unsubscribeOnError}) =>
                                        listen((Request req) => onData(req, req.response),
                                          onError: onError, onDone: onDone, unsubscribeOnError: unsubscribeOnError);

  RouteStreamSubscription listen (void onData(Request request),
                                  { void onError(AsyncError error),
                                    void onDone(),
                                    bool unsubscribeOnError}) {

    if (this._closed)
      throw new Exception('RouteStream is closed');

    RouteStreamSubscription subscription = new RouteStreamSubscription(this, onData,
        onError : onError, onDone : onDone, unsubscribeOnError : unsubscribeOnError);

    this.subscription = subscription;

    return subscription;
  }

  void _add (Request request) {
    if (this.subscription != null && !this.isPaused) {
      this.subscription._handleData(request);
    }
  }

  void _addError (AsyncError error) {
    this.subscription._handleError(error);
  }

  void _close () {
    this._closed = true;
    subscription._handleDone();
  }
}

class _RouteStreamSubscription implements RouteStreamSubscription {
  RouteStream stream;
  Function dataHandler;
  Function doneHandler;
  Function errorHandler;
  bool unsubscribeOnError = true;
  int _paused = 0;
  bool get isPaused => this._paused > 0;

  _RouteStreamSubscription (this.stream, dataHandler,
                                errorHandler, doneHandler, unsubscribeOnError) {

    if (dataHandler == null)
      throw new Exception ('Subscription\'s onData handler is not defined');

    this.onData(dataHandler);
    this.onError(errorHandler);
    this.onDone(doneHandler);

    if (unsubscribeOnError == null)
      unsubscribeOnError = true;

    this.unsubscribeOnError = unsubscribeOnError;
  }

  void cancel () {
    this.stream._close();
  }

  void onData (void handleData(Request request)) {
    this.dataHandler = (Request request) {
      this._tryHandleData(handleData, request);
    };
  }

  void onError (void handleError(AsyncError error)) {
    this.errorHandler = handleError;
  }

  void onDone (void handleDone()) {
    this.doneHandler = handleDone;
  }



  pause ([Future resumeSignal]) {
    this._paused++;

    if (resumeSignal != null)
      resumeSignal.then((data) {
        this.resume();
      });
  }

  void resume () {
    this._paused--;
  }

  void _handleData (Request request) {
    this.dataHandler(request);
  }

  void _handleError (AsyncError error) {
    if (this.errorHandler != null)
      this.errorHandler(error);
  }

  void _handleDone () {
    if (this.doneHandler != null)
      this.doneHandler();
  }

  void _tryHandleData (void handleData(Request request), Request request) {
    try {
      handleData(request);
    } catch (e) {
      if (this.errorHandler != null) {
        this.errorHandler(e);
      } else {
        Response res = request.response;
        res.status = HttpStatus.INTERNAL_SERVER_ERROR;
        res.close();
      }

      if (this.unsubscribeOnError == true)
        this.cancel();
    }
  }

}
