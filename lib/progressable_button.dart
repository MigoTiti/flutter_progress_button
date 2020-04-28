library progressable_button;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as Vectors;
import 'package:vibrate/vibrate.dart';

class ProgressableTextButton extends StatelessWidget {
  final String text;
  final TextStyle textStyle;

  final VoidCallback onClick;

  final Stream<bool> loadingStream;
  final Stream<bool> enabledStream;
  final Stream<Exception> errorStream;

  final double expandedSize;
  final bool big;

  final EdgeInsets margin;
  final EdgeInsets loadingMargin;
  final EdgeInsets padding;

  final BorderRadius idleBorderRadius;
  final BorderRadius loadingBorderRadius;

  final Widget loadingChild;

  final Color enabledColor;
  final Color disabledColor;
  final Color errorColor;

  final List<BoxShadow> shadow;

  ProgressableTextButton({
    this.loadingStream,
    this.enabledStream,
    this.errorStream,
    this.onClick,
    this.text,
    this.textStyle,
    this.expandedSize,
    this.loadingMargin,
    this.idleBorderRadius,
    this.loadingBorderRadius,
    this.padding = const EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 20,
    ),
    bool big,
    this.margin,
    this.enabledColor,
    this.loadingChild,
    this.disabledColor,
    this.errorColor,
    this.shadow,
  }) : this.big = big ?? true;

  @override
  Widget build(BuildContext context) {
    return ProgressableButton(
      padding: padding,
      errorStream: errorStream,
      onClick: onClick,
      enabledColor: enabledColor,
      enabledStream: enabledStream,
      loadingStream: loadingStream,
      expandedSize: expandedSize,
      idleBorderRadius: idleBorderRadius,
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

class ProgressableButton extends StatefulWidget {
  final Widget enabledChild;
  final Widget loadingChild;

  final VoidCallback onClick;

  final Stream<bool> loadingStream;
  final Stream<bool> enabledStream;
  final Stream<Exception> errorStream;

  final double expandedSize;
  final bool big;

  final EdgeInsets margin;
  final EdgeInsets loadingMargin;
  final EdgeInsets padding;

  final Color enabledColor;
  final Color disabledColor;
  final Color errorColor;

  final BorderRadius idleBorderRadius;
  final BorderRadius loadingBorderRadius;

  final List<BoxShadow> shadow;

  ProgressableButton({
    this.loadingStream,
    this.enabledStream,
    this.errorStream,
    this.onClick,
    this.expandedSize,
    @required this.enabledChild,
    this.loadingChild,
    bool big,
    List<BoxShadow> shadow,
    Color enabledColor,
    Color errorColor,
    Color disabledColor,
    BorderRadius idleBorderRadius,
    BorderRadius loadingBorderRadius,
    EdgeInsets padding,
    EdgeInsets loadingMargin,
    EdgeInsets margin,
  })  : this.padding =
            padding ?? ProgressableButtonDefaultConfiguration.idlePadding,
        this.loadingMargin =
            loadingMargin ?? ProgressableButtonDefaultConfiguration.loadingMargin,
        this.margin = margin ?? ProgressableButtonDefaultConfiguration.idleMargin,
        this.loadingBorderRadius = loadingBorderRadius ??
            ProgressableButtonDefaultConfiguration.loadingBorderRadius,
        this.idleBorderRadius = idleBorderRadius ??
            ProgressableButtonDefaultConfiguration.idleBorderRadius,
        this.enabledColor =
            enabledColor ?? ProgressableButtonDefaultConfiguration.enabledColor,
        this.errorColor =
            errorColor ?? ProgressableButtonDefaultConfiguration.errorColor,
        this.disabledColor =
            disabledColor ?? ProgressableButtonDefaultConfiguration.disabledColor,
        this.shadow = shadow ?? ProgressableButtonDefaultConfiguration.shadow,
        this.big = big ?? true;

  @override
  _ProgressableButtonState createState() => _ProgressableButtonState();
}

class _ProgressableButtonState extends State<ProgressableButton>
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
              color: _backgroundColor,
              borderRadius: _borderRadius,
              boxShadow: widget.shadow,
            ),
            child: Stack(
              children: <Widget>[
                AnimatedSize(
                  vsync: this,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                  child: _child,
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
                      borderRadius: _borderRadius,
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

  Widget get _child {
    if (_loading) return widget.loadingChild ?? _buildDefaultLoadingWidget();

    return Container(
      padding: widget.padding,
      width: widget.expandedSize,
      child: widget.enabledChild,
    );
  }

  BorderRadius get _borderRadius {
    if (_loading) return widget.loadingBorderRadius;

    return widget.idleBorderRadius;
  }

  Color get _backgroundColor {
    if (_inErrorAnimation)
      return widget.errorColor ?? Theme.of(context).errorColor;

    if (_loading || !_enabled)
      return widget.disabledColor ?? Theme.of(context).disabledColor;

    return widget.enabledColor ?? Theme.of(context).primaryColor;
  }

  Widget _buildDefaultLoadingWidget() {
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

class ProgressableButtonDefaultConfiguration {
  static EdgeInsets idleMargin = EdgeInsets.zero;
  static EdgeInsets loadingMargin = EdgeInsets.zero;

  static EdgeInsets idlePadding = const EdgeInsets.symmetric(vertical: 10);

  static BorderRadius idleBorderRadius = BorderRadius.circular(10);
  static BorderRadius loadingBorderRadius = BorderRadius.circular(100);

  static Color enabledColor;
  static Color errorColor;
  static Color disabledColor;

  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      blurRadius: 5.0,
      spreadRadius: 0.25,
      offset: Offset(0, 3),
    ),
  ];
}
