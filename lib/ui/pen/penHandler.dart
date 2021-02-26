import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:painter/painter.dart';


class PenHandler {
  PainterController _controller;
  PainterController get controller => _controller;

  List<Offset> offsetPoints = List();


  PenHandler(){
    _controller = _newController();
  }

  PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 2.0;
    controller.backgroundColor = Color(0x00ffffff);
    return controller;
  }

  void releasePen(){
    offsetPoints.clear();
    _controller.finish();
    _controller.dispose();
  }
}
