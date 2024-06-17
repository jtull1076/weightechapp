import 'package:flutter/material.dart';

class FullScreenWidget extends StatelessWidget {
  const FullScreenWidget(
      {required this.child,
      super.key,
      this.backgroundColor = Colors.black,
      this.backgroundIsTransparent = true,
      required this.disposeLevel});

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel disposeLevel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
                opaque: false,
                barrierColor: backgroundIsTransparent
                    ? Colors.white.withOpacity(0)
                    : backgroundColor,
                pageBuilder: (BuildContext context, _, __) {
                  return FullScreenPage(
                    backgroundColor: backgroundColor,
                    backgroundIsTransparent: backgroundIsTransparent,
                    disposeLevel: disposeLevel,
                    child: child,
                  );
                }));
      },
      child: child,
    );
  }
}

enum DisposeLevel { high, medium, low }

class FullScreenPage extends StatefulWidget {
  const FullScreenPage(
      {required this.child,
      super.key,
      this.backgroundColor = Colors.black,
      this.backgroundIsTransparent = true,
      this.disposeLevel = DisposeLevel.medium});

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel disposeLevel;

  @override
  _FullScreenPageState createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage> {
  double initialPositionY = 0;

  double currentPositionY = 0;

  double positionYDelta = 0;

  double opacity = 1;

  double disposeLimit = 150;

  Duration animationDuration = Duration.zero;


  @override
  void initState() {
    super.initState();
    setDisposeLevel();
  }

  setDisposeLevel() {
    setState(() {
      if (widget.disposeLevel == DisposeLevel.high) {
        disposeLimit = 300;
      }
      else if (widget.disposeLevel == DisposeLevel.medium) {
        disposeLimit = 200;
      }
      else {
        disposeLimit = 100;
      }
    });
  }

  void _startVerticalDrag(details) {
    setState(() {
      initialPositionY = details.globalPosition.dy;
    });
  }

  void _whileVerticalDrag(details) {
    setState(() {
      currentPositionY = details.globalPosition.dy;
      positionYDelta = currentPositionY - initialPositionY;
      setOpacity();
    });
  }

  setOpacity() {
    double tmp = positionYDelta < 0
        ? 1 - ((positionYDelta / 1000) * -1)
        : 1 - (positionYDelta / 1000);

    if (tmp > 1) {
      opacity = 1;
    }
    else if (tmp < 0) {
      opacity = 0;
    }
    else {
      opacity = tmp;
    }
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      opacity = 0.5;
    }
  }

  _endVerticalDrag(DragEndDetails details) {
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        opacity = 1;
        positionYDelta = 0;
      });

      Future.delayed(animationDuration).then((_){
        setState(() {
          animationDuration = Duration.zero;
        });
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundIsTransparent
          ? Colors.transparent
          : widget.backgroundColor,
      body: GestureDetector(
        onVerticalDragStart: (details) => _startVerticalDrag(details),
        onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
        onVerticalDragEnd: (details) => _endVerticalDrag(details),
        child: Container(
          color: widget.backgroundColor.withOpacity(opacity),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: animationDuration,
                curve: Curves.fastOutSlowIn,
                top: 0 + positionYDelta,
                bottom: 0 - positionYDelta,
                left: 0,
                right: 0,
                child: widget.child,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, top: 30),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF224190),
                    iconSize: 30,
                    onPressed: () {
                      setState(() {
                        animationDuration = const Duration(milliseconds: 300);
                        opacity = 0.5;
                      });
                      Navigator.of(context).pop();
                    },
                  )
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}