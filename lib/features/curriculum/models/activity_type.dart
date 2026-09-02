/// The six user-activity primitives the client's curriculum document
/// defines in its "How Every Exercise Works" section: Listen, Repeat, Read,
/// Speak, Record, Reflect. A single exercise can involve more than one.
enum ActivityType { listen, repeat, read, speak, record, reflect }

ActivityType? activityTypeFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'listen':
      return ActivityType.listen;
    case 'repeat':
      return ActivityType.repeat;
    case 'read':
      return ActivityType.read;
    case 'speak':
      return ActivityType.speak;
    case 'record':
      return ActivityType.record;
    case 'reflect':
      return ActivityType.reflect;
    default:
      return null;
  }
}

List<ActivityType> activityTypesFromJsonList(List<dynamic> raw) {
  return raw
      .map((e) => activityTypeFromString(e as String))
      .whereType<ActivityType>()
      .toList();
}
