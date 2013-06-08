Uri copyUri (Uri uri, {String untilPathSegment}) {
  var pathSegments = uri.pathSegments;
  
  if (untilPathSegment != null) {
    var indexOfLastSegment = pathSegments.indexOf(untilPathSegment);
    
    if (indexOfLastSegment >= 0)
      pathSegments = pathSegments.sublist(0, indexOfLastSegment + 1);
  }
  
  return new Uri(
      scheme: uri.scheme, 
      userInfo: uri.userInfo, 
      host: uri.host, 
      port: uri.port, 
      pathSegments: pathSegments, 
      query:  uri.query, 
      fragment: uri.fragment);
}