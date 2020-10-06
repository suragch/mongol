# mongol

This library is a collection of Flutter widgets for displaying traditional Mongolian vertical text.

## Contents

Currently this project contains the following widgets:

- `MongolText`
- `MongolRichText`
- `MongolAlertDialog`

### Setup

Previous versions of this library included a Mongolian font. However, as of version 0.6.0, the font is removed. This allows the library to be smaller and also gives developers the freedom to choose any Mongolian font they like.

Since it's likely that some of your user's devices won't have a Mongolian font installed, you should include at least one Mongolian font with your project. Here is what you need to do:

#### 1. Get a font

You can find a font from the following companies:

- [Menksoft](http://www.menksoft.com/site/alias__menkcms/2805/Default.aspx)
- [Delehi](http://www.delehi.com/cn/2693.html)
- [One BolorSoft font](https://www.mngl.net/downloads/fonts/MongolianScript.ttf)

[This one](http://www.menksoft.com/Portals/_MenkCms/Products/Fonts/MenksoftOpenType1.02/MQG8F02.ttf) from Menksoft is the one that used to be included in the library.

#### 2. Add the font to your project

You can get directions to do that [here](https://medium.com/@suragch/how-to-use-a-custom-font-in-a-flutter-app-911763c162f5) and [here](https://flutter.dev/docs/cookbook/design/fonts). 

Basically you just need to create an assets/fonts folder for it and then declare the font in pubspec.yaml like this:

```yaml
flutter:
  fonts:
    - family: MenksoftQagan
      fonts:
        - asset: assets/fonts/MQG8F02.ttf
```

You can call the family name whatever you want, but this string is what you will use in the next step.

#### 3. Set the default Mongolian font for your app

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

### MongolText

This is a vertical text version of Flutter's `Text` widget. Left-to-right line wrapping is supported. In the image below you can see that the widget responds to resizing the parent. In this case the platform is Mac, but the library works on Android, iOS, and the web. It probably works on Windows, too, but this is untested.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_text.gif)

### MongolRichText

The `MongolRichText` widget takes a `TextSpan` widget just like a `RichText` widget does. (However, `WidgetSpan`s are not supported at this time.) Because of this you can style text using `TextStyle` as usual. The following image shows a few of the main options:

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_rich_text.png)

You should use `MongolText.rich` in order to use the app's default Mongol font as described in the Setup section above. `MongolText.rich` creates a `MongolRichText` widget using the theme's default style. If you use `MongolRichText` directly, then you must specify a Mongolian font in the `TextSpan`'s `TextStyle`.

### MongolAlertDialog

This alert dialog works mostly the same as the Flutter `AlertDialog`.

![](https://github.com/suragch/mongol/blob/master/example/supplemental/mongol_alert_dialog.png)

### Keyboard and vertical TextField

These are not part of `mongol` library yet, but you can see an example of how to make a custom in-app keyboard and a vertical TextField in the example app that's included with this library. Here is a screenshot from the demo app:

![](https://github.com/suragch/mongol/blob/master/example/supplemental/keyboard.png)

The text field is just a standard `TextField` rotated by 90 degrees. For that reason, it only supports single line input.

### TODO

- Mirror entire Flutter `Text` widget stack.
- Rotate CJK and emoji characters to proper orientation