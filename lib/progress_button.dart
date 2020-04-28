library progress_button;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as Vectors;
import 'package:vibrate/vibrate.dart';

class ProgressTextButton extends StatelessWidget {
  final VoidCallback onClick;
  final String text;
  final TextStyle textStyle;
  final Stream<bool> loadingStream;
  final Stream<bool> enabledStream;
  final Stream<Exception> errorStream;
  final double expandedSize;
  final bool big;
  final EdgeInsets margin;
  final EdgeInsets loadingMargin;
  final EdgeInsets padding;
  final Color enabledColor;
  final BorderRadius borderRadius;
  final Widget loadingChild;

  ProgressTextButton({
    this.loadingStream,
    this.enabledStream,
    this.errorStream,
    this.onClick,
    this.text,
    this.textStyle,
    this.expandedSize,
    this.loadingMargin,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 20,
    ),
    this.big = true,
    this.margin,
    this.enabledColor,
    this.loadingChild,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressButton(
      padding: padding,
      errorStream: errorStream,
      onClick: onClick,
      enabledColor: enabledColor,
      enabledStream: enabledStream,
      loadingStream: loadingStream,
      expandedSize: expandedSize,
      idleBorderRadius: borderRadius,
      loadingMargin: loadingMargin,
      margin: margin,
      big: big,
      loadingChild: loadingChild,
      enabledChild: Text(
        text,
        style: textStyle != null
            ? textStyle
            : big
                ? Theme.of(context).textTheme.body1
                : Theme.of(context).textTheme.body2,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ProgressButton extends StatefulWidget {
  final VoidCallback onClick;
  final Widget enabledChild;
  final Widget loadingChild;
  final Stream<bool> loadingStream;
  final Stream<bool> enabledStream;
  final Stream<Exception> errorStream;
  final double expandedSize;
  final bool big;
  final EdgeInsets margin;
  final EdgeInsets loadingMargin;
  final EdgeInsets padding;
  final Color enabledColor;
  final BorderRadius idleBorderRadius;

  ProgressButton({
    this.loadingStream,
    this.enabledStream,
    this.errorStream,
    this.onClick,
    this.expandedSize,
    @required this.enabledChild,
    this.idleBorderRadius,
    this.big = true,
    this.enabledColor,
    this.loadingChild,
    EdgeInsets padding,
    EdgeInsets loadingMargin,
    EdgeInsets margin,
  })  : this.padding =
            padding ?? ProgressButtonDefaultConfiguration.idlePadding,
        this.loadingMargin =
            loadingMargin ?? ProgressButtonDefaultConfiguration.loadingMargin,
        this.margin = margin ?? ProgressButtonDefaultConfiguration.idleMargin;

  @override
  _ProgressButtonState createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton>
    with TickerProviderStateMixin {
  StreamSubscription _errorSubscription;
  StreamSubscription _loadingSubscription;
  StreamSubscription _enabledSubscription;

  AnimationController _errorAnimationController;

  bool _loading = false;
  bool _enabled = true;
  bool _inErrorAnimation = false;

  @override
  void initState() {
    super.initState();

    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener(
        (status) {
          switch (status) {
            case AnimationStatus.dismissed:
              setState(() => _inErrorAnimation = false);
              break;
            case AnimationStatus.forward:
              setState(() => _inErrorAnimation = true);
              break;
            case AnimationStatus.reverse:
              setState(() => _inErrorAnimation = true);
              break;
            case AnimationStatus.completed:
              setState(() => _inErrorAnimation = false);
              break;
          }
        },
      );

    _errorSubscription = widget.errorStream
        ?.where(
          (event) => event != null,
        )
        ?.listen(
          (_) => _startShake(),
        );

    _loadingSubscription = widget.loadingStream
        ?.where(
          (event) => event != null,
        )
        ?.listen(
          (loading) => setState(() => _loading = loading),
        );

    _enabledSubscription = widget.enabledStream
        ?.where(
          (event) => event != null,
        )
        ?.listen(
          (enabled) => setState(() => _enabled = enabled),
        );
  }

  void _startShake() async {
    Vibrate.vibrate();

    _errorAnimationController.forward(
        from: _errorAnimationController.lowerBound);
  }

  Vectors.Vector3 _lerpShake() {
    double progress = _errorAnimationController.value;
    double offset = sin(progress * pi * 10.0);
    return Vectors.Vector3(offset * 8, 0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = _loading
        ? BorderRadius.circular(100)
        : widget.idleBorderRadius ??
            ProgressButtonDefaultConfiguration.idleBorderRadius;

    return IgnorePointer(
      ignoring: _inErrorAnimation || !_enabled || _loading,
      child: Container(
        margin: _loading ? widget.loadingMargin : widget.margin,
        child: AnimatedBuilder(
          animation: _errorAnimationController,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.translation(_lerpShake()),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
            decoration: BoxDecoration(
              color: _inErrorAnimation
                  ? Theme.of(context).errorColor
                  : _loading || !_enabled
                      ? Theme.of(context).disabledColor
                      : widget.enabledColor ??
                          ProgressButtonDefaultConfiguration.enabledColor ??
                          Theme.of(context).primaryColor,
              borderRadius: borderRadius,
              boxShadow: [ProgressButtonDefaultConfiguration.boxShadow],
            ),
            child: Stack(
              children: <Widget>[
                AnimatedSize(
                  vsync: this,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                  child: _loading
                      ? widget.loadingChild ??
                          _buildDefaultLoadingWidget(context)
                      : Container(
                          padding: widget.padding,
                          width: widget.expandedSize,
                          child: widget.enabledChild,
                        ),
                ),
                Positioned(
                  right: 0,
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onClick,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLoadingWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.big ? 12 : 8),
      child: SizedBox(
        height: widget.big ? 24.0 : 16.0,
        width: widget.big ? 24.0 : 16.0,
        child: const CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _loadingSubscription?.cancel();
    _enabledSubscription?.cancel();

    _errorAnimationController.dispose();

    super.dispose();
  }
}

class ProgressButtonDefaultConfiguration {
  static EdgeInsets idleMargin = EdgeInsets.zero;
  static EdgeInsets loadingMargin = EdgeInsets.zero;

  static EdgeInsets idlePadding = const EdgeInsets.symmetric(vertical: 10);

  static BorderRadius idleBorderRadius =
      const BorderRadius.all(Radius.circular(10));

  static Color enabledColor;

  static BoxShadow boxShadow = BoxShadow(
    color: Colors.grey.withOpacity(0.5),
    blurRadius: 5.0,
    spreadRadius: 0.25,
    offset: Offset(0, 3),
  );
}
