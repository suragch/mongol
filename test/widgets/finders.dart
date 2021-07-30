// Copyright 2014 The Flutter Authors.
// Copyright 2021 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';
import 'package:mongol/src/editing/mongol_editable_text.dart';

/// Some frequently used widget [MongolFinder]s.
const CommonMongolFinders findMongol = CommonMongolFinders._();

/// Provides lightweight syntax for getting frequently used widget [Finder]s.
///
/// This class is instantiated once, as [findMongol].
class CommonMongolFinders {
  const CommonMongolFinders._();

  /// Finds [MongolText] and [MongolEditableText] widgets containing string equal to the
  /// `text` argument.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(findMongol.text('Back'), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder text(String text, {bool skipOffstage = true}) =>
      _MongolTextFinder(text, skipOffstage: skipOffstage);

  /// Finds [MongolText] and [MongolEditableText] widgets which contain the given
  /// `pattern` argument.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(findMongol.textContain('Back'), findsOneWidget);
  /// expect(findMongol.textContain(RegExp(r'(\w+)')), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder textContaining(Pattern pattern, {bool skipOffstage = true}) =>
      _TextContainingFinder(pattern, skipOffstage: skipOffstage);

  /// Looks for widgets that contain a [MongolText] descendant with `text`
  /// in it.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Suppose you have a button with text 'Update' in it:
  /// new Button(
  ///   child: new MongolText('Update')
  /// )
  ///
  /// // You can find and tap on it like this:
  /// tester.tap(findMongol.widgetWithText(Button, 'Update'));
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder widgetWithText(Type widgetType, String text,
      {bool skipOffstage = true}) {
    return find.ancestor(
      of: findMongol.text(text, skipOffstage: skipOffstage),
      matching: find.byType(widgetType, skipOffstage: skipOffstage),
    );
  }

  /// Finds MongolTooltip widgets with the given message.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(findMongol.byTooltip('Back'), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byTooltip(String message, {bool skipOffstage = true}) {
    return byWidgetPredicate(
      (Widget widget) => widget is MongolTooltip && widget.message == message,
      skipOffstage: skipOffstage,
    );
  }

  /// Finds widgets using a widget [predicate].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(findMongol.byWidgetPredicate(
  ///   (Widget widget) => widget is Tooltip && widget.message == 'Back',
  ///   description: 'widget with tooltip "Back"',
  /// ), findsOneWidget);
  /// ```
  ///
  /// If [description] is provided, then this uses it as the description of the
  /// [Finder] and appears, for example, in the error message when the finder
  /// fails to locate the desired widget. Otherwise, the description prints the
  /// signature of the predicate function.
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidgetPredicate(WidgetPredicate predicate,
      {String? description, bool skipOffstage = true}) {
    return _WidgetPredicateFinder(predicate,
        description: description, skipOffstage: skipOffstage);
  }
}

class _MongolTextFinder extends MatchFinder {
  _MongolTextFinder(this.text, {bool skipOffstage = true})
      : super(skipOffstage: skipOffstage);

  final String text;

  @override
  String get description => 'text "$text"';

  @override
  bool matches(Element candidate) {
    final widget = candidate.widget;
    if (widget is MongolText) {
      if (widget.data != null) {
        return widget.data == text;
      }
      assert(widget.textSpan != null);
      return widget.textSpan!.toPlainText() == text;
    } else if (widget is MongolEditableText) {
      return widget.controller.text == text;
    }
    return false;
  }
}

class _TextContainingFinder extends MatchFinder {
  _TextContainingFinder(this.pattern, {bool skipOffstage = true})
      : super(skipOffstage: skipOffstage);

  final Pattern pattern;

  @override
  String get description => 'text containing $pattern';

  @override
  bool matches(Element candidate) {
    final widget = candidate.widget;
    if (widget is MongolText) {
      if (widget.data != null) {
        return widget.data!.contains(pattern);
      }
      assert(widget.textSpan != null);
      return widget.textSpan!.toPlainText().contains(pattern);
    } else if (widget is MongolEditableText) {
      return widget.controller.text.contains(pattern);
    }
    return false;
  }
}

class _WidgetPredicateFinder extends MatchFinder {
  _WidgetPredicateFinder(this.predicate,
      {String? description, bool skipOffstage = true})
      : _description = description,
        super(skipOffstage: skipOffstage);

  final WidgetPredicate predicate;
  final String? _description;

  @override
  String get description =>
      _description ?? 'widget matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate.widget);
  }
}
