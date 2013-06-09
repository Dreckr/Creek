library transformer;

import 'dart:async';
import 'dart:io';
import 'creek.dart';
import 'route.dart';

part 'transformer_impl.dart';

//var keyTransformer = new CreekContextTransformer<HttpRequest, HttpRequest>(handleData:
//  (CreekContext context, EventSink sink) {
//    print(context.route.uri);
//    sink.add(context.request);
//  });

abstract class CreekContextTransformer <S, T> implements StreamTransformer <CreekContext<S>, T> {
  
  factory CreekContextTransformer ({
    void handleData(CreekContext<S> data, EventSink<T> sink),
    void handleError(error, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}) => 
      new _CreekContextTransformer(handleData: handleData, handleError: handleError, handleDone: handleDone);
  
  Stream<T> bind (Stream<CreekContext<S>> stream);
  
}

class CreekContext <S> {
  Creek creek;
  Route route;
  S request;
  
  CreekContext (this.creek, this.route, this.request);
}

class ContextHandler<S> implements StreamTransformer <S, CreekContext<S>> {
  StreamTransformer _transformer;
  
  ContextHandler (Creek creek, Route route) : 
    _transformer = 
      new StreamTransformer<dynamic, CreekContext>(
          handleData: 
            (request, eventSink) => 
                eventSink.add(new CreekContext(creek, route, request)));
  
  Stream bind (Stream stream) =>  this._transformer.bind(stream);
}
