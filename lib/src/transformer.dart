library transformer;

import 'dart:async';
import 'route.dart';

part 'transformer_impl.dart';

abstract class CreekContextTransformer <S, T> implements StreamTransformer <CreekContext<S>, T> {
  
  factory CreekContextTransformer ({
    void handleData(CreekContext<S> data, EventSink<T> sink),
    void handleError(error, StackTrace stackTrace, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}) => 
      new _CreekContextTransformer(handleData: handleData, handleError: handleError, handleDone: handleDone);
  
  Stream<T> bind (Stream<CreekContext<S>> stream);
  
}

class CreekContext <S> {
  Route route;
  S request;
  
  CreekContext (this.route, this.request);
}

class ContextHandler<S> implements StreamTransformer <S, CreekContext<S>> {
  StreamTransformer _transformer;
  
  ContextHandler (Route route) : 
    _transformer = 
      new StreamTransformer<dynamic, CreekContext>.fromHandlers(
          handleData: 
            (request, eventSink) => 
                eventSink.add(new CreekContext(route, request)));
  
  Stream bind (Stream stream) =>  this._transformer.bind(stream);
}
