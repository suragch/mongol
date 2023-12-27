## [7.0.0] - 2023.12.27

- Update APIs to match the Flutter 3.16 release. (#47) (with lots of help from @Satsrag)
- It's unclear if this would be a breaking change for those still using a lower version of Flutter, but making a major version bump just in case.
- Added `TextHeightBasis` (similar to `TextWidthBasis` for `Text`) at the lower levels (ex, `MongolTextPainter`) but not all the way up to `MongolText`. This affects whether the widget height is the height of the `parent` when line wrapping or the height of the `longestLine`. The default right now is `parent`. See #49 for progress.
- One known issue is emojis and CJK characters are not correctly horizontally centered in some circumstances. (#48)

## [6.0.1] - 2023.08.22

- Fix images not displaying in pub.dev documentation.

## [6.0.0] - 2023.08.22

- Fixes for breaking changes in Flutter 2.13, mostly related to the text selection API.

## [5.0.0] - 2023.05.15

- Update APIs to match the Flutter 3.10 and Dart 3.0 release. (#45) (@Satsrag)
- This is a major version bump because of the breaking changes in the Flutter update and the new requirement to use Dart 3.0.
- The known issues in the version 4.0.0 changelog notes still exist.

## [4.0.0] - 2023.02.10

- Update APIs to match the Flutter 3.7 release. Theoretically this may have added some improvements, but the main reason was that Flutter 3.7 broke the old package. This is a major version bump because some of the API changes were potentially breaking for users of `mongol` 3.4.0. (#38)
- There are some known issues related to the input decorator for `MongolTextField` (#29, #30, #32, #39, #40, #41). Help requested to fix these. This release exports `MongolEditableText` if anyone needs a more low-level option. 
- The `MongolText` API appears to be unaffected by this update, but keep an eye on performance for large text strings. `MongolTextPainter` and `MongolParagraph` have a new `dispose` method and it is unclear how this may affect performance/memory for better or worse.

## [3.4.0] - 2023.01.05

- Remove `DefaultMongolTextEditingShortcuts` from `MongolEditableTextState` (#35) (@Satsrag)
- To switch the behavior of left/right and up/down keys in `MongolEditableText`, developers now need to add `MongolTextEditingShortcuts` at the top of the widget tree. See [#33](https://github.com/suragch/mongol/issues/33) for discussion.

## [3.3.1] - 2022.12.31

-  Fix: crash when MongolTextField contain a line end with ' \n' (#34) (@Satsrag)

## [3.3.0] - 2022.11.29

- Fix label problems on outlined input border with `MongolOutlineInputBorder` (#28).
- Export `TextAlignHorizontal` for `MongolTextField`.

## [3.2.0] - 2022.10.22

- Updating internal code to remove compiler warnings. Required minimum of Flutter 2.17.
- Added example app demo for `MongolTextField` to show options for input decorations.
- Export `MongolRenderEditable` to get cursor location (#31).

## [3.1.0] - 2022.09.13

- Added `MongolTextField` back in with fixes. (@Satsrag)

## [3.0.2] - 2022.02.10

- Fix for bug caused by Flutter 2.10 upgrade (#20) (@azhansy)

## [3.0.1] - 2022.01.10

- Exported `MongolTextPainter` so that it is public now.

## [3.0.0] - 2021.12.18

- Removed `MongolTextField` and related classes from the library. The Flutter 2.8 update broke the editing widgets again. Even if we fixed this break, there was still the major issue of crashing when scrolling `MongolTextField`. It is easier to remove `MongolTextField` now and start over from scratch, either with the Flutter text editing widgets or with something like SuperEditor.

## [2.2.2] - 2021.11.7

- Attempted to fix the issue with `MongolTextField` crashing when text content needs to scroll. However, since the issue is still not fixed, there is a deprecation warning on this class. Hopefully the error can be fixed with a future update or a replacement can be found, but currently there is nothing.

## [2.2.1] - 2021.9.20

- Fix the errors caused by the Flutter 2.5 update.
- Removed lots of tests (unfortunately) because the Flutter 2.5 update broke something internally with the custom Flutter testing implementation for the Mongol widgets.
- Fixed the buttons.
- Known issue: MongolTextField still crashes when text content needs to scroll.

## [2.2.0] - 2021.8.2

- Added buttons: `MongolTextButton`, `MongolOutlineButton`, and `MongolElevatedButton`

## [2.1.0] - 2021.7.30

- Added `MongolPopupMenuButton` along with its `MongolPopupMenuEntry`, `MongolPopupMenuDivider`, `MongolPopupMenuItem`, `showMongolMenu`
- Added `MongolTooltip` (and `MongolIconButton` that needs it) so that `MongolPopupMenuButton` will have a vertical text tooltip.
- Added `MongolListTile` so that it can be used as a `MongolPopupMenuItem` or in a horizontal ListView.
- Added supporting (though incomplete) tests for `MongolPopupMenuButton` and `MongolListTile`.
- Switched to flutter_lints for the demo project.

## [2.0.2] - 2021.7.15

- Fixed `MongolTextField` tap selection not working on iOS (#12)
- Switched to flutter_lints instead of pedantic

## [2.0.1] - 2021.6.10

- Fixed bug for range error when selecting past end of text in `MongolTextField`
- Fixed `MongolTextAlign` regression (#6)

## [2.0.0] - 2021.5.28

- Flutter 2.2 broke some of the internal workings of this package. This update fixes those.
- This update increases the major version to 2 because an automatic update for projects still on Flutter 2.0 would probably break things.
- There are no significant new features with this release, but there are numerous internal changes to match changes made to the Flutter text editing widgets.
- There are several known issues with this release. Please open a GitHub issue if they are affecting your app.

## [1.1.0] - 2021.3.13

- Implemented MongolTextAlign (supports top, center, bottom, justify)
- Known issue: Spaces after words are included in the measurements so MongolTextAlign.bottom aligns the space to the bottom and not the text itself.

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
