import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:painter/painter.dart';


class PenHandler {
  PainterController controller;

  List<Offset> offsetPoints = List();

  PenHandler(){
    controller = _newController();
  }

  PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 2.0;
    controller.backgroundColor = Color(0x00ffffff);
    return controller;
  }

  void releasePen(){
    offsetPoints.clear();
    controller.finish();
    controller.dispose();
  }
}

class PenListItems extends StatefulWidget {
  //const PenListItems({Key key}) : super(key: key);
  final PainterController controller;

  PenListItems({this.controller});

  @override
  _PenListItemsState createState() => _PenListItemsState();
}

class _PenListItemsState extends State<PenListItems> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
                '굵기', style: TextStyle(fontSize: 10.0, color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: thicknessButton(thickness: 2.0, iconSize: 15.0)
                ),
                Expanded(
                  child: thicknessButton(thickness: 5.0, iconSize: 20.0)
                ),
                Expanded(
                  child: thicknessButton(thickness: 10.0, iconSize: 25.0)
                )
              ]),

          Container(
            height: 20.0,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.black,
                trackHeight: 1.0,
                thumbColor: widget.controller.drawColor,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
              ),
              child: Slider(
                value: widget.controller.thickness,
                onChanged: (double value) => setState(() {
                  widget.controller.thickness = value;
                }),
                min: 1.0,
                max: 20.0,
              ),
            ),
          ),
          //const Divider(height: 1, indent: 5, endIndent: 5, color: Colors.white),

          Container(
            alignment: Alignment.centerLeft,
            child: Text(
                '색상', style: TextStyle(fontSize: 10.0, color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                        children: [
                          colorButton(context: context, color: Colors.pinkAccent),
                          colorButton(context: context, color: Colors.orangeAccent),
                          colorButton(context: context, color: Colors.yellowAccent)
                        ]),
                  ),

                  Expanded(
                    child: Row(
                        children: [
                          colorButton(context: context, color: Colors.greenAccent),
                          colorButton(context: context, color: Colors.blueAccent),
                          colorButton(context: context, color: Colors.indigoAccent)
                        ]),
                  ),

                  Expanded(
                    child: Row(
                        children: [
                          colorButton(context: context, color: Colors.purpleAccent),
                          colorButton(context: context, color: Colors.white),
                          colorButton(context: context, color: Colors.black)
                        ]),
                  )
                ]),
          ),
        ],
      ),
    );
  }

  Widget thicknessButton({double thickness, double iconSize}) {
    return  IconButton(
        icon: Icon(
            Icons.show_chart,
            size: iconSize,
            color: widget.controller.drawColor),
        onPressed: () {
          setState(() {
            widget.controller.thickness = thickness;
          });
          Navigator.of(context).pop();
        });
  }

  Expanded colorButton({BuildContext context, Color color, double height = 24.0}) {
    return Expanded(
      child: FlatButton(
          color: Colors.grey[300],
          shape: CircleBorder(),
          height: height,
          child: colorMenuItem(color),
          onPressed: (){
            widget.controller.drawColor = color;
            Navigator.of(context).pop();
          }),
    );
  }

  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.drawColor = color;
        });
        Navigator.of(context).pop();
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 4.0),
          height: 18,
          width: 18,
          color: color,
        ),
      ),
    );
  }
}