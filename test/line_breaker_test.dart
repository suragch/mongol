import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol_paragraph.dart';

void main() {
  test('BreakSegments is empty for empty string', () {
    final text = '';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.isEmpty, equals(true));
  });

  test('BreakSegments breaks multiple spaces', () {
    final text = '  ';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments: one space attaches to previous word', () {
    final text = 'hello  ';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first, equals('hello '));
    expect(breakSegments.last, equals(' '));
  });
  
  test('BreakSegments finds no breaks in a single word', () {
    final text = 'hello';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(1));
  });
  
  test('BreakSegments breaks on space', () {
    final text = 'hello world';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first, equals('hello '));
    expect(breakSegments.last, equals('world'));
  });

  test('BreakSegments breaks on newline', () {
    final text = 'hello\nworld';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
    expect(breakSegments.first, equals('hello\n'));
    expect(breakSegments.last, equals('world'));
  });

  test('BreakSegments breaks for emojis', () {
    final text = '😊😊';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments breaks for CJK', () {
    final text = '你好';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(2));
  });

  test('BreakSegments breaks for mixed CJK', () {
    final text = 'hello 你好 asdf';
    final breakSegments = BreakSegments(text);
    expect(breakSegments.length, equals(5));
  });

}