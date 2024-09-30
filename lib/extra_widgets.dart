import 'package:flutter/material.dart';
import 'dart:async';

import 'package:apivideo_player/apivideo_player.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:apivideo_player/src/widgets/common/apivideo_player_multi_text_button.dart';


class FullScreenWidget extends StatelessWidget {
  const FullScreenWidget(
      {required this.child,
      super.key,
      this.backgroundColor = Colors.black,
      this.backgroundIsTransparent = true,
      required this.disposeLevel,
      this.callFullscreen = false,
      this.expandOnTap = true});

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel disposeLevel;
  final bool expandOnTap;
  final bool callFullscreen;
  

  @override
  Widget build(BuildContext context) {
    if (callFullscreen) {
      Future.microtask(() {
        if (context.mounted) {
          _expand(context);
        }
      });
    }

    return GestureDetector(
      onTap: () {
        if (expandOnTap) _expand(context);
      },
      child: child,
    );
  }

  void _expand(BuildContext context) {
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
            }
        )
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

  double opacity = 0;

  double disposeLimit = 150;

  Duration animationDuration = Duration.zero;


  @override
  void initState() {
    super.initState();
    setDisposeLevel();
    Timer(const Duration(seconds: 0), () {
      setState(() => opacity = 1);
    });
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                        opacity = 0;
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


/// The overlay of the video player.
/// It displays the controls, time slider and the action bar.
class CustomPlayerOverlay extends StatefulWidget {
  const CustomPlayerOverlay(
      {super.key, required this.controller, this.style, this.onToggleFullscreen, this.onItemPress});

  /// The controller for the player.
  final ApiVideoPlayerController controller;

  /// The style of the player.
  final PlayerStyle? style;

  /// The callback to be called when an item (play, pause,...) is clicked (used to show the overlay).
  final VoidCallback? onItemPress;
  final VoidCallback? onToggleFullscreen;

  @override
  State<CustomPlayerOverlay> createState() => _CustomPlayerOverlayState();
}

class _CustomPlayerOverlayState extends State<CustomPlayerOverlay>
    with TickerProviderStateMixin {
  final _timeSliderController = TimeSliderController();
  final _controlsBarController = ControlsBarController();
  final _settingsBarController = SettingsBarController();

  Timer? _timeSliderTimer;

  late final ApiVideoPlayerControllerEventsListener _listener =
      ApiVideoPlayerControllerEventsListener(
    onReady: () async {
      _updateTimes();
    },
    onPlay: () async {
      _onPlay();
    },
    onPause: () async {
      _onPause();
    },
    onSeek: () async {
      _updateCurrentTime();
    },
    onSeekStarted: () async {
      if (_controlsBarController.state.didEnd) {
        _controlsBarController.state = ControlsBarState.paused;
      }
    },
    onEnd: () async {
      _stopRemainingTimeUpdates();
      _controlsBarController.state = ControlsBarState.ended;
    },
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
    // In case controller is already created
    widget.controller.isCreated.then((bool isCreated) async => {
          if (isCreated)
            {
              _updateTimes(),
              _updateVolume(),
              _updateMuted(),
              widget.controller.isPlaying.then((isPlaying) => {
                    if (isPlaying) {_onPlay()}
                  })
            }
        });
  }

  @override
  void didUpdateWidget(CustomPlayerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    _stopRemainingTimeUpdates();
    widget.controller.removeListener(_listener);

    _timeSliderController.dispose();
    _controlsBarController.dispose();
    _settingsBarController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PointerInterceptor(
        child: buildOverlay(),
      );

  Widget buildOverlay() => Stack(
        children: [
          Positioned(
              top: 0,
              right: 0,
              child: CustomSettingsBar(
                  controller: _settingsBarController,
                  onVolumeChanged: (volume) {
                    widget.controller.setVolume(volume);
                    if (widget.onItemPress != null) {
                      widget.onItemPress!();
                    }
                  },
                  onToggleFullscreen: () {
                    if (widget.onToggleFullscreen != null) {
                      widget.onToggleFullscreen!();
                    }
                  },
                  onToggleMute: () async {
                    final isMuted = await widget.controller.isMuted;
                    widget.controller.setIsMuted(!isMuted);
                    if (widget.onItemPress != null) {
                      widget.onItemPress!();
                    }
                  },
                  onSpeedRateChanged: (speed) {
                    widget.controller.setSpeedRate(speed);
                    if (widget.onItemPress != null) {
                      widget.onItemPress!();
                    }
                  },
                  style: widget.style?.settingsBarStyle)),
          Center(
            child: ControlsBar(
              controller: _controlsBarController,
              onBackward: () {
                widget.controller.seek(const Duration(seconds: -10));
                if (widget.onItemPress != null) {
                  widget.onItemPress!();
                }
              },
              onForward: () {
                widget.controller.seek(const Duration(seconds: 10));
                if (widget.onItemPress != null) {
                  widget.onItemPress!();
                }
              },
              onPause: () {
                widget.controller.pause();
                _onPause();
                if (widget.onItemPress != null) {
                  widget.onItemPress!();
                }
              },
              onPlay: () {
                widget.controller.play();
                _onPlay();
                if (widget.onItemPress != null) {
                  widget.onItemPress!();
                }
              },
              onReplay: () {
                widget.controller.setCurrentTime(const Duration(seconds: 0));
                widget.controller.play();
                if (widget.onItemPress != null) {
                  widget.onItemPress!();
                }
              },
              style: widget.style?.controlsBarStyle,
            ),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: TimeSlider(
                controller: _timeSliderController,
                style: widget.style?.timeSliderStyle,
                onChanged: (Duration value) {
                  widget.controller.setCurrentTime(value);
                  if (widget.onItemPress != null) {
                    widget.onItemPress!();
                  }
                },
              )),
        ],
      );

  void _onPlay() {
    _startRemainingTimeUpdates();
    if (mounted) {
      _controlsBarController.state = ControlsBarState.playing;
    }
  }

  void _onPause() {
    _stopRemainingTimeUpdates();
    if (mounted) {
      _controlsBarController.state = ControlsBarState.paused;
    }
  }

  void _startRemainingTimeUpdates() {
    _timeSliderTimer?.cancel();
    _timeSliderTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        final isLive = await widget.controller.isLive;
        if (isLive) {
          _updateTimes();
        } else {
          _updateCurrentTime();
        }
      },
    );
  }

  void _stopRemainingTimeUpdates() {
    _timeSliderTimer?.cancel();
    _timeSliderTimer = null;
  }

  void _updateTimes() async {
    Duration currentTime = await widget.controller.currentTime;
    Duration duration = await widget.controller.duration;
    if (mounted) {
      _timeSliderController.setTime(currentTime, duration);
    }
  }

  void _updateCurrentTime() async {
    Duration currentTime = await widget.controller.currentTime;
    if (mounted) {
      _timeSliderController.currentTime = currentTime;
    }
  }

  void _updateVolume() async {
    double volume = await widget.controller.volume;
    if (mounted) {
      _settingsBarController.volume = volume;
    }
  }

  void _updateMuted() async {
    bool isMuted = await widget.controller.isMuted;
    if (mounted) {
      _settingsBarController.isMuted = isMuted;
    }
  }
}


class CustomSettingsBar extends StatefulWidget {
  const CustomSettingsBar(
      {super.key,
      required this.controller,
      this.onToggleMute,
      this.onToggleFullscreen,
      this.onVolumeChanged,
      this.onSpeedRateChanged,
      this.style});

  final SettingsBarController controller;

  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleFullscreen;
  final ValueChanged<double>? onVolumeChanged;

  final ValueChanged<double>? onSpeedRateChanged;

  final SettingsBarStyle? style;

  @override
  State<CustomSettingsBar> createState() => _CustomSettingsBarState();
}

class _CustomSettingsBarState extends State<CustomSettingsBar> {

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              if (widget.onToggleFullscreen != null) {
                widget.onToggleFullscreen!();
              }
            },
            style: widget.style?.buttonStyle
          ),
          MultiTextButton(
            keysValues: const {
              '0.5x': 0.5,
              '1.0x': 1.0,
              '1.2x': 1.2,
              '1.5x': 1.5,
              '2.0x': 2.0,
            },
            defaultKey: "1.0x",
            onValueChanged: (speed) {
              if (widget.onSpeedRateChanged != null) {
                widget.onSpeedRateChanged!(speed);
              }
            },
            size: 17,
            style: widget.style?.buttonStyle,
          )
        ]);
  }
}