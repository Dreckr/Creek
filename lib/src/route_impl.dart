part of route;

class _RouteNode implements RouteNode {
  RouteType type;
  List<RouteNode> children = [];
  List<Middleware> middlewares = [];
  List<String> keysNames = [];
  RouteNode fatherNode;
  RouteStreamController controller;
  String stepName;
  bool get isClosed => controller == null || !controller.hasSubscribers;

  _RouteNode (this.type, this.fatherNode, this.stepName);

  RouteNode findNode (List<String> routeSteps) {
    return this._findNode(routeSteps, new List.from(this.keysNames));
  }

  RouteNode _findNode (List<String> routeSteps, List<String> keysNames) {
    if (routeSteps.length == 0) {
      this.keysNames = keysNames;
      return this;
    }

    String step = routeSteps.removeAt(0);
    RouteType routeType;

    if (step.startsWith('*')) {
      routeType = RouteType.GENERIC;
    } else if (step.startsWith(':')) {
      routeType = RouteType.KEY;
      step = step.substring(1);
      keysNames.add(step);
    } else {
      routeType = RouteType.STRICT;
    }

    for (var child in this.children)
      if ((routeType == RouteType.STRICT && child.stepName == step) ||
          (child.type == routeType && routeType != RouteType.STRICT))
        return child._findNode(routeSteps, keysNames);

    var childNode = new RouteNode(routeType, this, step);
    this.children.add(childNode);
    return childNode._findNode(routeSteps, keysNames);
  }

  bool routeRequest (RoutingRequest routingRequest) {
    if (routingRequest.routeSteps.length == 0) {
      if (!this.isClosed) {
        this._parseKeys(routingRequest);
        return this.controller.add(routingRequest.request);
      } else {
        return false;
      }
    }

    String step = routingRequest.routeSteps.removeAt(0);
    RouteNode strictChild, genericChild;
    for (var child in this.children) {
      if (child.stepName == step) {
        strictChild = child;
      } else if (child.type == RouteType.KEY) {
        routingRequest.keys.add(step);
        genericChild = child;
      } else if (child.type == RouteType.GENERIC && strictChild == null) {
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

  openStream () {
    if (this.isClosed)
      this.controller = new RouteStreamController();
  }

  close (bool closeChildren)  {
    if (this.controller != null)
      this.controller.close();

    if (closeChildren)
      for (RouteNode child in children)
        child.close(true);
  }

  _parseKeys (RoutingRequest routingRequest) {
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


  bool add (Request request) {
    return this.sink.add(request);
  }

  addError (error, [stackTrace]) {
    AsyncError asyncError;
    if (error is AsyncError) {
      asyncError = error;
    } else {
      asyncError = new AsyncError(error, stackTrace);
    }

    this.sink.addError(asyncError);
  }

  close () {
    if (!this.isClosed)
      this.sink.close();
  }

  signalError (AsyncError error) {
    this.sink.addError(error);
  }

}

class _RouteStreamSinkImpl implements RouteStreamSink {
  RouteStream _stream;

  _RouteStreamSinkImpl (RouteStream stream) : this._stream = stream;

  bool add (Request request) {
    return this._stream._add(request);
  }

  addError (AsyncError error) {
    this._stream._addError(error);
  }

  close () {
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

  bool _add (Request request) {
    if (this.subscription != null && !this.isPaused) {
      return this.subscription.handleData(request);
    }

    return false;
  }

  _addError (AsyncError error) {
    this.subscription.handleError(error);
  }

  _close () {
    this._closed = true;
    subscription.handleDone();
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

  cancel () {
    this.stream._close();
  }

  onData (void handleData(Request request)) {
    this.dataHandler = (Request request) {
      this._tryHandleData(handleData, request);
    };
  }

  onError (void handleError(AsyncError error)) {
    this.errorHandler = handleError;
  }

  onDone (void handleDone()) {
    this.doneHandler = handleDone;
  }



  pause ([Future resumeSignal]) {
    this._paused++;

    if (resumeSignal != null)
      resumeSignal.then((data) {
        this.resume();
      });
  }

  resume () {
    this._paused--;
  }

  bool handleData (Request request) {
    if (this.dataHandler == null)
      return false;

    this.dataHandler(request);
    return true;
  }

  handleError (AsyncError error) {
    if (this.errorHandler != null)
      this.errorHandler(error);
  }

  handleDone () {
    if (this.doneHandler != null)
      this.doneHandler();
  }

  _tryHandleData (void handleData(Request request), Request request) {
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
