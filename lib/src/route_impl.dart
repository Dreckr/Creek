part of route;

class _RouteNode implements RouteNode {
  RouteNodeType type;
  List<RouteNode> children = [];
  //List<Middleware> middlewares = [];
  List<String> keysNames = [];
  StreamController<HttpRequest> controller;
  String stepName;
  bool get isClosed => controller == null || controller.isClosed;
  bool get isPaused => this.isClosed || controller.isPaused || !controller.hasListener;

  _RouteNode (this.type, this.stepName);

  RouteNode findNode (List<String> routeSteps, [List<String> keysNames]) {
    if (keysNames == null)
      keysNames = [];
    else
      keysNames = new List.from(keysNames);
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
        return child.findNode(routeSteps, keysNames);

    var childNode = new RouteNode(routeType, step);
    this.children.add(childNode);
    return childNode.findNode(routeSteps, keysNames);
  }

  bool routeRequest (RoutingRequest routingRequest) {
    if (routingRequest.routeSteps.length == 0) {
      if (!this.isClosed && !this.isPaused) {
        this._parseKeys(routingRequest);
        this.controller.add(routingRequest.httpRequest);
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
      this.controller = new StreamController<HttpRequest>();
  }

  void closeStream (bool closeChildren)  {
    if (this.controller != null)
      this.controller.close();

    if (closeChildren)
      for (RouteNode child in children)
        child.closeStream(true);
  }

  void _parseKeys (RoutingRequest routingRequest) {
    var i = 0;

    for (String key in routingRequest.keys) {
      routingRequest.httpRequest.queryParameters[this.keysNames[i]] = key;
      i++;
    }
  }

}