// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mongol/src/editing/mongol_editable_text.dart';
import 'package:mongol/src/editing/mongol_render_editable.dart';

import 'mongol_widget_tester.dart';

// ignore_for_file: omit_local_variable_types

// Returns the first RenderEditable.
MongolRenderEditable findRenderEditable(MongolWidgetTester tester) {
  final RenderObject root = tester.renderObject(find.byType(MongolEditableText));
  expect(root, isNotNull);

  late MongolRenderEditable renderEditable;
  void recursiveFinder(RenderObject child) {
    if (child is MongolRenderEditable) {
      renderEditable = child;
      return;
    }
    child.visitChildren(recursiveFinder);
  }
  root.visitChildren(recursiveFinder);
  expect(renderEditable, isNotNull);
  return renderEditable;
}

List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
  return points.map<TextSelectionPoint>((TextSelectionPoint point) {
    return TextSelectionPoint(
      box.localToGlobal(point.point),
      point.direction,
    );
  }).toList();
}

Offset textOffsetToPosition(MongolWidgetTester tester, int offset) {
  final MongolRenderEditable renderEditable = findRenderEditable(tester);
  final List<TextSelectionPoint> endpoints = globalize(
    renderEditable.getEndpointsForSelection(
      TextSelection.collapsed(offset: offset),
    ),
    renderEditable,
  );
  expect(endpoints.length, 1);
  return endpoints[0].point + const Offset(0.0, -2.0);
}
