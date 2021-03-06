## [1.0.0] - 2021.3.6

- Null safe
- Added `MongolTextField` and supporting classes
- Since `MongolTextField` fills in the largest missing gap for Mongolian text rendering, this library will now be marked as 1.0.0. This signifies feature completeness though there are some known bugs and it would be good for another version to include some keyboards.
- Filled in missing functionality in `MongolParagraph` and `MongolTextPainter`.

## [0.8.0-nullsafety.0] - 2020.11.27

- Migrated to sound null safety

## [0.7.1] - 2020.10.26

- Lowered the minimum version number requirement for the `meta` dependency.

## [0.7.0] - 2020.10.24

- Support for rotating emoji and CJK characters.

## [0.6.1] - 2020.10.10

- Added static analysis options.
- Fixed warnings and errors from the static analysis.
- Implemented `MongolTextPainter.getPositionForOffset` with tests
- Close MongolDialog on button click in demo app

## [0.6.0] - 2020.10.2

- Added `MongolRichText` with support for `TextSpan` and its substring text styles.
- Added `MongolText.rich` constructor to support using a default font theme.
- Implemented `textScaleFactor`. It existed before but didn't do anything.
- Removed the default Menksoft font that was included with the library. This creates a bit more setup but makes the library smaller and allows developers to use any Mongolian font. Also removed MongolFont class.
- Added documentation modified from the standard Flutter docs.
- Changed the license to be in alignment with the Flutter BSD-3 license.
- Updated the demos to include a keyboard and vertical `TextField`. These are not in the library yet, but should be fairly easy to reproduce by studying the demos.
- Added more tests.

## [0.5.0] - 2020.5.31

- Added hit testing to `MongolText` and its associated classes so that a `GestureDetector` can be applied to it.
- Added the `textScaleFactor` parameter to `MongolText`.
- Added `debugFillProperties()` to various `MongolText` related classes.

## [0.4.1] - 2020.2.21

- Change unsupported 2018 text theme items to 2014 version in `MongolAlertDialog`

## [0.4.0] - 2020.2.19

- Added `MongolAlertDialog`.

## [0.3.2] - 2020.1.28

- Fixed bug: Spaces after a newline character caused newline char to be inserted in `ParagraphBuilder`.

## [0.3.1] - 2020.1.5

- Minor changes. Was going to include `mongol_code` as a part of this package but released it as a separate Dart package instead.

## [0.3.0] - 2019.11.29

* Added a default Mongolian font.
* Hiding `MongolRichText` for now since TextSpans are not yet supported.

## [0.2.0] - 2019.11.26

* Added support for new line characters.

## [0.1.0] - 2019.11.24

* Refactored into `MongolText` and `MongolRichText` widgets to more closely match `Text` and `RichText`.

## [0.0.1] - 2019.7.23

* Provides a `MongolText` widget that handles line wrapping at spaces.
* Doesn't handle new lines or styling.
