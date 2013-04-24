library utils;

List<String> createRouteSteps (String path) {
  return path.split('/').where((step) => step.length > 0).toList();
}