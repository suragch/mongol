// Copyright 2026 Suragch.
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

enum Pick { a, b }

Finder tileFor(Pick p) => find.byWidgetPredicate(
    (w) => w is MongolRadioListTile<Pick> && w.value == p);

void main() {
  testWidgets('a RadioGroup ancestor drives selection', (tester) async {
    Pick? chosen = Pick.a;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StatefulBuilder(
        builder: (context, setState) => RadioGroup<Pick>(
          groupValue: chosen,
          onChanged: (v) => setState(() => chosen = v),
          child: const Row(
            children: <Widget>[
              MongolRadioListTile<Pick>(value: Pick.a, title: MongolText('a')),
              MongolRadioListTile<Pick>(value: Pick.b, title: MongolText('b')),
            ],
          ),
        ),
      )),
    ));

    expect(chosen, Pick.a);
    await tester.tap(tileFor(Pick.b));
    await tester.pumpAndSettle();
    expect(chosen, Pick.b, reason: 'tapping a tile reports through the group');
  });

  testWidgets('tiles are enabled by the group alone', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RadioGroup<Pick>(
        groupValue: Pick.a,
        onChanged: (_) {},
        child: const Row(
          children: <Widget>[
            MongolRadioListTile<Pick>(value: Pick.a, title: MongolText('a')),
          ],
        ),
      )),
    ));

    final MongolListTile inner =
        tester.widget<MongolListTile>(find.byType(MongolListTile));
    expect(inner.enabled, isTrue,
        reason: 'no onChanged is given, so the group has to enable it');
  });

  testWidgets('the deprecated groupValue and onChanged still work',
      (tester) async {
    Pick? chosen = Pick.a;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StatefulBuilder(
        builder: (context, setState) => Row(
          children: <Widget>[
            for (final p in Pick.values)
              // ignore: deprecated_member_use_from_same_package
              MongolRadioListTile<Pick>(
                value: p,
                groupValue: chosen,
                onChanged: (v) => setState(() => chosen = v),
                title: MongolText(p.name),
              ),
          ],
        ),
      )),
    ));

    await tester.tap(tileFor(Pick.b));
    await tester.pumpAndSettle();
    expect(chosen, Pick.b);
  });

  testWidgets('enabled: false blocks interaction', (tester) async {
    Pick? chosen = Pick.a;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RadioGroup<Pick>(
        groupValue: chosen,
        onChanged: (v) => chosen = v,
        child: const Row(
          children: <Widget>[
            MongolRadioListTile<Pick>(
                value: Pick.b, enabled: false, title: MongolText('b')),
          ],
        ),
      )),
    ));

    await tester.tap(tileFor(Pick.b), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen, Pick.a, reason: 'a disabled tile must not report');
  });

  testWidgets('toggleable deselects, which needs the group value to be right',
      (tester) async {
    Pick? chosen = Pick.b;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => RadioGroup<Pick>(
            groupValue: chosen,
            onChanged: (v) => setState(() => chosen = v),
            child: const Row(
              children: <Widget>[
                MongolRadioListTile<Pick>(
                    value: Pick.b, toggleable: true, title: MongolText('b')),
              ],
            ),
          ),
        ),
      ),
    ));

    // Tapping the already selected tile clears it, which only happens if the
    // tile sees itself as checked against the group's value.
    await tester.tap(tileFor(Pick.b));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });
}
