import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:planner/planner_date_pos.dart';
import 'package:planner/planner_entry.dart';

import 'planner.dart';

class Manager {
  Manager(
      {@required this.config,
      @required this.entries}) {
    _canvasWidth = config.blockWidth * config.labels.length;
    _canvasHeight = config.blockHeight * (config.maxHour - config.minHour);
    entries.forEach((entry) {
      entry.createPainters(config.minHour);
    });
  }

  void update(
      {@required PlannerConfig config,
      @required List<PlannerEntry> entries}) {
    this.config = config;
    this.entries = entries;
    _canvasWidth = config.blockWidth * config.labels.length;
    _canvasHeight = config.blockHeight * (config.maxHour - config.minHour);
    entries.forEach((entry) {
      entry.createPainters(config.minHour);
    });
  }

  PlannerConfig config;
  List<PlannerEntry> entries;

  int _canvasWidth;
  int _canvasHeight;

  double _screenWidth;
  double _screenHeight;
  double _scale = 1;

  double _vScroll = 0;
  double get vScroll => _vScroll;
  set vScroll(double value) {
    _vScroll = value;
    _limitVScroll();
  }

  double _hScroll = 0;
  double get hScroll => _hScroll;
  set hScroll(double value) {
    _hScroll = value;
    _limitHScroll();
  }

  double _minZoom = 0.5;
  double _zoom = 1;
  double _previousZoom = 0;
  double get zoom => _zoom;
  set zoom(double value) {
    if (value > 3)
      _zoom = 3;
    else if (value < _minZoom)
      _zoom = _minZoom;
    else {
      _zoom = value;
      if (_previousZoom != 0) {
        double _zoomFactor = _zoom - _previousZoom;
        vScroll += _screenHeight * -_zoomFactor;
      }
      _previousZoom = zoom;
    }
  }

  Offset eventsPainterOffset = Offset.zero;

  Offset _touchPos;
  Offset get touchPos => _touchPos;
  set touchPos(Offset pos) {
    _touchPos = pos;
    if (_touchPos != null) {
      _touchPos -= eventsPainterOffset;
      _touchPos = getCanvasPosition(_touchPos);
    }
  }

  // method is used on double tap. Returns zero when not tapped on entry
  PlannerEntry getPlannerEntry(Offset position) {
    Offset canvasPos = getCanvasPosition(position - eventsPainterOffset);
    PlannerEntry result;
    entries.forEach((entry) {
      if (entry.canvasRect.contains(canvasPos)) {
        result = entry;
      }
    });
    return result;
  }

  PlannerDatePos getPlannerDatePos(Offset position) {
    Offset canvasPos = getCanvasPosition(position - eventsPainterOffset);
    PlannerDatePos result = new PlannerDatePos();
    result.day = (canvasPos.dx / config.blockWidth).floor();
    result.hour = config.minHour + (canvasPos.dy / 40).floor();
    // 30 and 15 minute time slots are used when zoomed in
    if (zoom > 2.25) {
      result.minutes = ((canvasPos.dy.toInt() % config.blockHeight) / 10).floor() * 15;
    } else if (zoom > 1.25) {
      result.minutes = ((canvasPos.dy.toInt() % config.blockHeight) / 20).floor() * 30;
    } else {
      result.minutes = 0;
    }
    return result;
  }

  void setSize(double width, double height) {
    this._screenWidth = width;
    this._screenHeight = height;
    _scale = this._screenWidth / 1000;
    _minZoom = _screenHeight / _canvasHeight / _scale;
    //debugPrint('scale: ${_scale.toString()}');
    _limitHScroll();
    _limitVScroll();
    //debugPrint('hscroll: $hScroll, canvasWidth: $_canvasWidth');
  }

  Offset getScreenPosition(Offset canvasPos) {
    return Offset(hScroll + canvasPos.dx * _scale,
        vScroll + canvasPos.dy * _scale * _zoom);
  }

  Offset getCanvasPosition(Offset screenPos) {
    return Offset((screenPos.dx - hScroll) / _scale,
        (screenPos.dy - vScroll) / _scale / _zoom);
  }

  Offset getPositionForHour(Offset pos) {
    return Offset(pos.dx * _scale, vScroll + pos.dy * _scale * _zoom);
  }

  Offset getPositionForLabel(Offset pos) {
    return Offset(hScroll + pos.dx * _scale, pos.dy * _scale);
  }

  void _limitHScroll() {
    double limit = -(_canvasWidth - _screenWidth / _scale) * _scale;
    if (limit >= 0 || _hScroll > 0) {
      _hScroll = 0;
    } else if (limit < 0 && _hScroll < limit) {
      _hScroll = limit;
    }
  }

  void _limitVScroll() {
    double limit =
        -(_canvasHeight * _zoom - _screenHeight - config.blockHeight) * _scale;
    if (limit >= 0 || _vScroll > 0) {
      _vScroll = 0;
    } else if (_vScroll < limit) {
      _vScroll = limit;
    }
  }
}
