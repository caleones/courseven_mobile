import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/utils/refresh_manager.dart';
import '../../core/utils/navigation_observer.dart';

mixin RevalidationMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  final _routeObserver = routeObserver;
  Timer? _poll;

  
  Future<void> revalidate({bool force = false}) async {}

  
  Duration? get pollingInterval => null;

  RefreshManager get refresh => Get.find<RefreshManager>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didPushNext() {
    _stopPolling();
  }

  @override
  void didPopNext() {
    
    revalidate();
    _startPollingIfNeeded();
  }

  @override
  void didPush() {
    
    _startPollingIfNeeded();
  }

  @override
  void didPop() {
    _stopPolling();
  }

  

  void _startPollingIfNeeded() {
    _poll?.cancel();
    final interval = pollingInterval;
    if (interval == null) return;
    _poll = Timer.periodic(interval, (_) => revalidate());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }
}
