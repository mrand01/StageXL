part of stagexl;

class EventDispatcher {

  Map<String, List<EventStream>> _eventStreams;

  //-----------------------------------------------------------------------------------------------

  EventStream<Event> on(String eventType, [int priority = 0]) {
    
    var eventStreams = _eventStreams;
    if (eventStreams == null) {
      eventStreams = new Map<String, List<EventStream>>();
      _eventStreams = eventStreams;
    }

    var eventStreamList = eventStreams[eventType];
    if (eventStreamList == null) {
      eventStreamList = new List();
      eventStreams[eventType] = eventStreamList;
    }
    
    EventStream eventStream = new EventStream._internal(this, eventType, priority);
    eventStreamList.add(eventStream);

    return eventStream;
  }

  //-----------------------------------------------------------------------------------------------

  bool hasEventListener(String eventType) {

    var eventStreams = _eventStreams;
    if (eventStreams == null) return false;
    var eventStreamList = eventStreams[eventType];
    if (eventStreamList == null) return false;

    for (EventStream eventStream in eventStreamList) {
      if (eventStream.hasSubscriptions) {
        return true;
      }
    }
    
    return false;
  }

  StreamSubscription<Event> addEventListener(
      String eventType, EventListener eventListener, { bool useCapture: false, int priority: 0 }) {

    return useCapture
        ? this.on(eventType, priority).capture(eventListener)
        : this.on(eventType, priority).listen(eventListener);
  }
  
  void removeEventListener(String eventType, EventListener eventListener, { bool useCapture: false}) {
    var eventStreams = _eventStreams;
    if (eventStreams == null) return;
    var eventStreamList = eventStreams[eventType];
    if (eventStreamList == null) return;
    
    int eventStreamLength = eventStreamList.length;
    for (int i = 0; i < eventStreamLength; i++) {
      EventStream eventStream = eventStreamList[i];
      
      if (eventStream.hasSubscriptions) {
        int subLength = eventStream.subscriptions.length;
        for (int x = 0; x < subLength; x++) {
          EventStreamSubscription sub = eventStream.subscriptions[x];
          if (sub.eventListener == eventListener && sub.isCapturing == useCapture) {
            eventStreamList[i] = null;
          }
        }
      }
    }
    
    eventStreamList.removeWhere((EventStream s) => s == null);
  }

  void removeEventListeners(String eventType) {
    var eventStreams = _eventStreams;
    if (eventStreams == null) return;
    var eventStreamList = eventStreams[eventType];
    if (eventStreamList == null) return;
    
    int eventStreamLength = eventStreamList.length;
    for (int i = 0; i < eventStreamLength; i++) {
      EventStream eventStream = eventStreamList[i];
      
      if (eventStream.hasSubscriptions) {
        eventStream.cancelSubscriptions();
      }
    }
  }

  void dispatchEvent(Event event) {
    _dispatchEventInternal(event, this, EventPhase.AT_TARGET);
  }

  //-----------------------------------------------------------------------------------------------
  //-----------------------------------------------------------------------------------------------

  bool _hasPropagationEventListeners(Event event) {

    var eventStreams = _eventStreams;
    if (eventStreams == null) return false;
    var eventStreamList = eventStreams[event.type];
    if (eventStreamList == null) return false;
    
    for (EventStream eventStream in eventStreamList) {
      if (eventStream._hasPropagationSubscriptions(event)) {
        return true;
      }
    }
    
    return false;
  }

  _dispatchEventInternal(Event event, EventDispatcher target, int eventPhase) {

    event._stopsPropagation = false;
    event._stopsImmediatePropagation = false;

    var eventStreams = _eventStreams;
    if (eventStreams == null) return;
    var eventStreamList = eventStreams[event.type];
    if (eventStreamList == null) return;
    
    eventStreamList = new List.from(eventStreamList);
    eventStreamList.sort((EventStream x, EventStream y) {
      return (x.priority.compareTo(y.priority) * -1);
    });
    
    for (EventStream eventStream in eventStreamList) {
      eventStream._dispatchEventInternal(event, target, eventPhase);
    }
  }

}
