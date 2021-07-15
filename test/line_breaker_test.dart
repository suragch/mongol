import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/src/base/mongol_paragraph.dart';

void main() {
  test('BreakSegments is empty for empty string', () {
    const text = '';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.isEmpty, equals(true));
  });

  test('BreakSegments breaks multiple spaces', () {
    const text = '  ';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments: one space attaches to previous word', () {
    const text = 'hello  ';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first.text, equals('hello '));
    expect(breakSegments.last.text, equals(' '));
  });

  test('BreakSegments finds no breaks in a single word', () {
    const text = 'hello';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(1));
  });

  test('BreakSegments breaks on space', () {
    const text = 'hello world';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first.text, equals('hello '));
    expect(breakSegments.last.text, equals('world'));
  });

  test('BreakSegments breaks on newline', () {
    const text = 'hello\nworld';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first.text, equals('hello\n'));
    expect(breakSegments.last.text, equals('world'));
  });

  test('BreakSegments breaks for emojis', () {
    const text = '😊😊';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments breaks for CJK', () {
    const text = '你好';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments breaks for mixed CJK', () {
    const text = 'hello 你好 asdf';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(5));
  });

  test('BreakSegments does not break for embedded formatting chars', () {
    const text = 'ᠨᠠ\u200dᠢᠮᠠ';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(1));
  });

  test('BreakSegments differentiates nonrotated rotated mix', () {
    const text = 'a你';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });
}
