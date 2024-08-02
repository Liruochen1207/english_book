import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter/src/rendering/proxy_box.dart';
import 'package:flutter/src/services/mouse_tracking.dart';

import '../note_action.dart';

interface class InterFaceControllableWidget {
  late Offset scrollOffset;
  FocusNode focusNode = FocusNode();
  InterFaceControllableWidget? fatherWidget;
  Widget? child;
  Color? color;
  Color? fontColor;
  double? fontSize;
  Paint? paint;
  bool? debug;
  bool? dragAble;
  double? height;
  double? width;
  String? name;

  late ListenerRegisterHandler listenerRegister;
  late List<EventRegisterHandler> eventHandlerList;

}

typedef ListenerAction = NoteButtonAction;

enum ListenerType {
  onPointerDown,
  onPointerMove,
  onPointerUp,
  onPointerHover,
  onPointerCancel,
  onPointerPanZoomStart,
  onPointerPanZoomUpdate,
  onPointerPanZoomEnd,
  onPointerSignal,
}

class CustomPointerUpEvent extends PointerEvent {
  int buttons = 0;
  void setLastButton(int newBtn) {
    buttons = newBtn;
  }

  @override
  PointerEvent copyWith({int? viewId, Duration? timeStamp, int? pointer, PointerDeviceKind? kind, int? device, Offset? position, Offset? delta, int? buttons, bool? obscured, double? pressure, double? pressureMin, double? pressureMax, double? distance, double? distanceMax, double? size, double? radiusMajor, double? radiusMinor, double? radiusMin, double? radiusMax, double? orientation, double? tilt, bool? synthesized, int? embedderId}) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  PointerEvent transformed(Matrix4? transform) {
    // TODO: implement transformed
    throw UnimplementedError();
  }
}

class EventRegisterHandler {
  late LogicalKeyboardKey _keyBind;
  bool _anyKeyCanTrigger = false;
  bool _onKeyUp = false;
  bool _onKeyDown = true;
  bool isAltPressed = false;
  bool isControlPressed = false;
  bool isMetaPressed = false;
  bool isShiftPressed = false;
  void Function() _event = () {};

  
  
  EventRegisterHandler([LogicalKeyboardKey? key]) {
    if (key!=null) {
      _keyBind = key;
      setOnlyKeyDownAlive();
    } else {
      _anyKeyCanTrigger = true;
    }

  }

  setHandler(void Function() handlerEvent) {
    _event = handlerEvent;
  }

  setAnyKeyCanTrigger(bool anyKeyCanTrigger) {
    _anyKeyCanTrigger = anyKeyCanTrigger;
  }

  setBothKeyAlive() {
    _onKeyUp = true;
    _onKeyDown = true;
  }

  setBothKeyDeath() {
    _onKeyUp = false;
    _onKeyDown = false;
  }

  setOnlyKeyUpAlive() {
    _onKeyUp = true;
    _onKeyDown = false;
  }

  setOnlyKeyDownAlive() {
    _onKeyUp = false;
    _onKeyDown = true;
  }

  run(RawKeyEvent event) {
    if (_anyKeyCanTrigger) {
      _event.call();
    }
    else if (event.logicalKey == _keyBind){
      if ((event is RawKeyDownEvent) && _onKeyDown){
        _event.call();
      }
      if ((event is RawKeyUpEvent) && _onKeyUp){
        _event.call();
      }
    }

  }

}

class ListenerRegisterHandler {
  Map<ListenerType, Map<int, List<void Function(PointerEvent event)>>>
      _listenerMap = {};
  PointerEvent customPointerUpEvent = CustomPointerUpEvent();

  void updateButton(int newBtn) {
    customPointerUpEvent = CustomPointerUpEvent()..setLastButton(newBtn);
  }

  void clean(){
    customPointerUpEvent = CustomPointerUpEvent();
  }

  void pointerUpListener(void Function(PointerEvent event) listener) {
    void Function(PointerEvent event) innerListener = (event) {
      listener.call(customPointerUpEvent);
    };
      addListener(ListenerType.onPointerUp, 0, innerListener);
  }

  void pointerScrollListener(void Function(PointerScrollEvent event) listener) {
    void Function(PointerEvent event) innerListener = (event) {
      listener.call(event as PointerScrollEvent);
    };
      addListener(ListenerType.onPointerSignal, 0, innerListener);
  }

  void addListener(ListenerType listenerType, int listenerAction,
      void Function(PointerEvent event) listener) {
    if (_listenerMap[listenerType] == null) {
      _listenerMap[listenerType] = {
        listenerAction: [listener]
      };
    } else if (_listenerMap[listenerType]?[listenerAction] == null) {
      _listenerMap[listenerType]?[listenerAction] = [listener];
    } else {
      _listenerMap[listenerType]?[listenerAction]?.add(listener);
    }
  }

  void run(ListenerType listenerType, int listenerAction, PointerEvent event) {
    if (_listenerMap[listenerType]?[listenerAction] != null) {
      _listenerMap[listenerType]?[listenerAction]?.forEach((element) {
        element.call(event);
      });
    }
  }

  void runListenerType(ListenerType listenerType, PointerEvent event) {
    if (_listenerMap[listenerType] == null) {
    } else {
      _listenerMap[listenerType]?.forEach((key, value) {
        for (var element in value) {
          element.call(event);
        }
      });
    }
  }
}