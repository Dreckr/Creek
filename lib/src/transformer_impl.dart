part of transformer;

class _CreekTransformer <S, T> implements CreekTransformer <S, T> {
  StreamTransformer <TransformationContext<S>, T> _streamTransformer;
  
  _CreekTransformer ({
      void handleData(TransformationContext<S> data, EventSink<T> sink),
      void handleError(error, EventSink<T> sink),
      void handleDone(EventSink<T> sink)}) {
    this._streamTransformer = new StreamTransformer(
        handleData: handleData, 
        handleError: handleError, 
        handleDone: handleDone);
  }
  
  Stream<T> bind (Stream<TransformationContext<S>> stream) => this._streamTransformer.bind(stream);
}