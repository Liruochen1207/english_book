import 'package:flutter/material.dart';

void main() {
  runApp(CustomBoard());
}

class CustomBoard extends StatelessWidget {
  var board = PaintBoard();
  _refresh() {
    board.refreshBoard();
  }

  void undo() {
    board.undo();
  }

  void redo() {
    board.redo();
  }

  void clear() {
    board.clear();
  }

  void setBackGroundColor(Color? color) {
    board.setBackGroundColor(color);
  }

  int getStrokeLength() => board.strokes.length;
  int getCacheLength() => board.cacheStroke.length;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // appBar: AppBar(
        //   title: Text('Paint Board'),
        // ),
        body: board,
      ),
    );
  }
}

class PaintBoard extends StatefulWidget {
  List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];
  List<List<Offset>> cacheStroke = [];
  int getStrokeLength() => strokes.length;
  int getCacheLength() => cacheStroke.length;
  Color? backgroundColor;
  void Function() refreshBoard = () {};

  void undo() {
    if (getStrokeLength() > 0) {
      cacheStroke.add(strokes.last);
      strokes.removeLast();
    }
    refreshBoard();
  }

  void redo() {
    if (getCacheLength() > 0) {
      strokes.add(cacheStroke.last);
      cacheStroke.removeLast();
    }
    refreshBoard();
  }

  void clear(){
    strokes = [];
    currentStroke = [];
    cacheStroke = [];
    refreshBoard();
  }

  void setBackGroundColor(Color? color) {
    backgroundColor = color;
    refreshBoard();
  }

  @override
  _PaintBoardState createState() => _PaintBoardState();
}

class _PaintBoardState extends State<PaintBoard> {
  bool redoVisible = false;
  bool undoVisible = false;
  get screenSize => MediaQuery.of(context).size;

  get screenHeight => screenSize.height;

  get screenWidth => screenSize.width;

  void updateButtonVisible (){
      redoVisible = widget.getCacheLength() > 0;
      undoVisible = widget.getStrokeLength() > 0;
  }


  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            widget.currentStroke = [];
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            widget.currentStroke
                .add(renderBox.globalToLocal(details.globalPosition));
          });
        },
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            widget.currentStroke
                .add(renderBox.globalToLocal(details.globalPosition));
          });
        },
        onPanEnd: (details) {
          setState(() {
            widget.strokes.add(List.from(widget.currentStroke));
            widget.currentStroke.clear();
            widget.cacheStroke.clear();
            updateButtonVisible();
          });
        },
        child: Container(
          color: widget.backgroundColor,
          child: Stack(
            children: [
              CustomPaint(
                painter: PaintBoardPainter(
                    strokes: widget.strokes,
                    currentStroke: widget.currentStroke),
                size: Size.infinite,
              ),
              Positioned(
                top: 20,
                left: screenWidth/40 + 80,
                child: Visibility(
                    visible: undoVisible,
                    child: IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.white,),//重做
                      onPressed: () {
                        setState(() {
                          widget.clear();
                          updateButtonVisible();
                        });
                      },
                    )),
              ),
              Positioned(
                top: 20,
                left: screenWidth/40 + 40,
                child: Visibility(
                    visible: redoVisible,
                    child: IconButton(
                      icon: Icon(Icons.redo, color: Colors.white,),//重做
                      onPressed: () {
                        setState(() {
                          widget.redo();
                          updateButtonVisible();
                        });
                      },
                    )),
              ),
              Positioned(
                top: 20,
                left: screenWidth/40,
                child: Visibility(
                    visible: undoVisible,
                    child: IconButton(
                      icon: Icon(Icons.undo, color: Colors.white,),//撤销
                      onPressed: () {
                        setState(() {
                          widget.undo();
                          updateButtonVisible();
                        });
                      },
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.refreshBoard = () {
      updateButtonVisible();
      setState(() {});
    };
  }
}

class PaintBoardPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  PaintBoardPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    double bei = 2.0;
    Paint fillDownPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.4)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0*bei
      ..style = PaintingStyle.stroke; // 填充风格
    Paint fillPaint = Paint()
      ..color = Colors.amber
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0*bei
      ..style = PaintingStyle.stroke; // 填充风格
    Paint paint = Paint()
          ..color = Colors.white
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.3*bei
          ..style = PaintingStyle.stroke // 设置画笔风格为线条而不是填充
        ;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      Path path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 0; i < stroke.length - 1; i++) {
        Offset p0 = i > 0 ? stroke[i - 1] : stroke[i];
        Offset p1 = stroke[i];
        Offset p2 = stroke[i + 1];
        Offset p3 = i < stroke.length - 2 ? stroke[i + 2] : stroke[i + 1];

        double x1 = p1.dx + (p2.dx - p0.dx) / 6;
        double y1 = p1.dy + (p2.dy - p0.dy) / 6;

        double x2 = p2.dx - (p3.dx - p1.dx) / 6;
        double y2 = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(x1, y1, x2, y2, p2.dx, p2.dy);
      }

      canvas.drawPath(path, fillDownPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);

    }

    if (currentStroke.length >= 2) {
      Path path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 0; i < currentStroke.length - 1; i++) {
        Offset p0 = i > 0 ? currentStroke[i - 1] : currentStroke[i];
        Offset p1 = currentStroke[i];
        Offset p2 = currentStroke[i + 1];
        Offset p3 = i < currentStroke.length - 2
            ? currentStroke[i + 2]
            : currentStroke[i + 1];

        double x1 = p1.dx + (p2.dx - p0.dx) / 6;
        double y1 = p1.dy + (p2.dy - p0.dy) / 6;

        double x2 = p2.dx - (p3.dx - p1.dx) / 6;
        double y2 = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(x1, y1, x2, y2, p2.dx, p2.dy);
      }

      canvas.drawPath(path, fillDownPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);

    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
