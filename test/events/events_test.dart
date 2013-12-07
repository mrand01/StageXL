library events_test;

import 'package:unittest/unittest.dart';
import 'package:stagexl/stagexl.dart';

void main() {
  test("removeEventListener_removes_correct_listener", () {
    EventDispatcher dispatcher = new EventDispatcher();
    List actual = new List();
    List expected = ["listener1", "listener3"];
    
    void listener1(Event event) {
      actual.add("listener1");
    }
    
    void listener2(Event event) {
      actual.add("listener2");
    }
    
    dispatcher.addEventListener("testEventType", listener1);
    dispatcher.addEventListener("testEventType", listener2);
    dispatcher.addEventListener("testEventType", (Event event) => actual.add("listener3"));
    dispatcher.removeEventListener("testEventType", listener2);
    dispatcher.dispatchEvent(new Event("testEventType"));
    expect(actual, equals(expected));
  });
}