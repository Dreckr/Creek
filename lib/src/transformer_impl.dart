part of transformer;

class _CreekContextTransformer <S, T> implements CreekContextTransformer <S, T> {
  StreamTransformer <CreekContext<S>, T> _streamTransformer;
  
  _CreekContextTransformer ({
    void handleData(CreekContext<S> data, EventSink<T> sink),
    void handleError(error, StackTrace stackTrace, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}) {
    this._streamTransformer = new StreamTransformer.fromHandlers(
        handleData: handleData, 
        handleError: handleError, 
        handleDone: handleDone);
  }
  
  Stream<T> bind (Stream<CreekContext<S>> stream) => this._streamTransformer.bind(stream);
}
