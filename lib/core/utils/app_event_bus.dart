import 'dart:async';



class AppEventBus {
  final _controller = StreamController<Object>.broadcast();
  Stream<Object> get stream => _controller.stream;

  void publish(Object event) => _controller.add(event);

  void dispose() => _controller.close();
}


class MembershipJoinedEvent {
  final String groupId;
  final String courseId;
  MembershipJoinedEvent(this.groupId, this.courseId);
}

class EnrollmentJoinedEvent {
  final String courseId;
  EnrollmentJoinedEvent(this.courseId);
}

class ActivityChangedEvent {
  final String courseId;
  ActivityChangedEvent(this.courseId);
}
