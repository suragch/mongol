# mongol

This library is a collection of Flutter widgets for displaying and editing traditional Mongolian vertical text.

## Displaying vertical text

`MongolText` is a vertical text version of Flutter's `Text` widget. Left-to-right line wrapping is supported. 

```dart
MongolText('ᠨᠢᠭᠡ ᠬᠣᠶᠠᠷ ᠭᠤᠷᠪᠠ ᠳᠦᠷᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤᠭ᠎ᠠ ᠳᠣᠯᠣᠭ᠎ᠠ ᠨᠠᠢᠮᠠ ᠶᠢᠰᠦ ᠠᠷᠪᠠ'),
```

The library supports mobile, web, and desktop.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_text.gif)

### Emoji and CJK characters

The library rotates emoji and CJK (Chinese, Japanese, and Korean) characters for proper orientation.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/emoji_cjk.png)

### Text styling

You add styling using `TextSpan` and/or `TextStyle`, just as you would for a `Text` widget.

```dart
MongolText.rich(
  textSpan,
  textScaleFactor: 2.5,
),
```

where `textSpan` is defined like so:

```dart
const textSpan = TextSpan(
  style: TextStyle(fontSize: 30, color: Colors.black),
  children: [
    TextSpan(text: 'ᠨᠢᠭᠡ\n', style: TextStyle(fontSize: 40)),
    TextSpan(text: 'ᠬᠣᠶᠠᠷ', style: TextStyle(backgroundColor: Colors.yellow)),
    TextSpan(
      text: ' ᠭᠤᠷᠪᠠ ',
      style: TextStyle(shadows: [
        Shadow(
          blurRadius: 3.0,
          color: Colors.lightGreen,
          offset: Offset(3.0, -3.0),
        ),
      ]),
    ),
    TextSpan(text: 'ᠳᠦᠷ'),
    TextSpan(text: 'ᠪᠡ ᠲᠠᠪᠤ ᠵᠢᠷᠭᠤ', style: TextStyle(color: Colors.blue)),
    TextSpan(text: 'ᠭ᠎ᠠ ᠨᠠᠢᠮᠠ '),
    TextSpan(text: 'ᠶᠢᠰᠦ ', style: TextStyle(fontSize: 20)),
    TextSpan(
        text: 'ᠠᠷᠪᠠ',
        style:
            TextStyle(fontFamily: 'MenksoftAmuguleng', color: Colors.purple)),
  ],
);
```

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_rich_text.png)

This all assumes you've added one or more Mongolian fonts to your app assets.

## Adding a Mongolian font

The library does not include a Mongolian font. This allows the library to be smaller and also gives developers the freedom to choose any Mongolian font they like.

Since it's likely that some of your users' devices won't have a Mongolian font installed, you should include at least one Mongolian font with your project. Here is what you need to do:

### 1. Get a font

You can find a font from the following companies:

- [Menksoft](http://www.menksoft.com/site/alias__menkcms/2805/Default.aspx)
- [Delehi](http://www.delehi.com/cn/2693.html)
- [One BolorSoft font](https://www.mngl.net/downloads/fonts/MongolianScript.ttf)

### 2. Add the font to your project

You can get directions to do that [here](https://medium.com/@suragch/how-to-use-a-custom-font-in-a-flutter-app-911763c162f5) and [here](https://flutter.dev/docs/cookbook/design/fonts). 

Basically you just need to create an **assets/fonts** folder for it and then declare the font in **pubspec.yaml** like this:

```yaml
flutter:
  fonts:
    - family: MenksoftQagan
      fonts:
        - asset: assets/fonts/MQG8F02.ttf
```

You can call the family name whatever you want, but this string is what you will use in the next step.

### 3. Set the default Mongolian font for your app

In your `main.dart` file, set the `fontFamily` for the app theme.

```dart
MaterialApp(
  title: 'My App',
  theme: ThemeData(fontFamily: 'MenksoftQagan'),
  home: MyHomePage(),
);
```

Now you won't have to manually set the font for every Mongolian text widget. If you want to use a different font for some widgets, though, you can still set the `fontFamily` as you normally would inside `TextStyle`.

You may also consider using [mongol_code](https://pub.dev/packages/mongol_code) with a Menksoft font if your users have devices that don't support OpenType Unicode font rendering. `mongol_code` converts Unicode to Menksoft code, which a Menksoft font can display without any special rendering requirements.

## Editing vertical text

You can use `MongolTextField` to receive and edit text from the system keyboard. This widget includes most of the functionality of the standard Flutter `TextField` widget.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_text_field.gif)

Here is it on iOS and Android interacting with a system keyboard:

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_text_field_large.gif)

There are a few known issues with `MongolTextField`:

- The cursor shows up on the right side of hint text.
- The gesture detection region for the left text selection handle does not appear directly on the handle.
- Some of the features are untested.
  
If you discover any other problems please open an issue. And if you have time to find the source of the known issues, that would be very helpful.

## Other widgets

### MongolAlertDialog

This alert dialog works mostly the same as the Flutter `AlertDialog`.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_alert_dialog.png)

### Keyboard

This are not part of `mongol` library yet, but you can see an example of how to make a custom in-app keyboard in the example app that's included with this library. Here is a screenshot from the demo app:

![](https://github.com/suragch/mongol/blob/master/example/supplemental/keyboard.png)

### TODO

- Improve keyboard
- Various other text based widgets
- Support `WidgetSpan`.
- Add missing tests (currently commented out)
- For MongolTextAlign.bottom don't count final space in line height