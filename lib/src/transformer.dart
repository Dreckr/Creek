library transformer;

import 'dart:async';
import 'creek.dart';
import 'route.dart';

part 'transformer_impl.dart';

abstract class CreekTransformer <S, T> implements StreamTransformer <TransformationContext<S>, T> {
  
  Stream<T> bind (Stream<TransformationContext<S>> stream);
  
}

class TransformationContext <S> {
  Creek creek;
  Route route;
  S request;
  
  TransformationContext (this.creek, this.route, this.request);
}