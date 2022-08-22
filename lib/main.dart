import 'dart:developer';
import 'dart:ui';
import 'package:drawing_app/newpage.dart';
import 'package:drawing_app/transition/enum.dart';
import 'package:drawing_app/transition/page_transition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_painter/flutter_painter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Painter Example",
      theme: ThemeData(
          primaryColor: Colors.brown, accentColor: Colors.amberAccent),
      home: const FlutterPainterExample(),
    );
  }
}

class FlutterPainterExample extends StatefulWidget {
  const FlutterPainterExample({Key? key}) : super(key: key);
  @override
  _FlutterPainterExampleState createState() => _FlutterPainterExampleState();
}

class _FlutterPainterExampleState extends State<FlutterPainterExample> {
  static const Color red = Color(0xFFFF0000);
  FocusNode textFocusNode = FocusNode();
  late PainterController controller;
  ui.Image? backgroundImage;
  Paint shapePaint = Paint()
    ..strokeWidth = 5
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void initState() {
    super.initState();
    controller = PainterController(
        settings: PainterSettings(
            text: TextSettings(
              focusNode: textFocusNode,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, color: red, fontSize: 18),
            ),
            freeStyle: const FreeStyleSettings(
              color: red,
              strokeWidth: 5,
            ),
            shape: ShapeSettings(
              paint: shapePaint,
            ),
            scale: const ScaleSettings(
              enabled: true,
              minScale: 1,
              maxScale: 5,
            ))
    );
    textFocusNode.addListener(onFocus);
    initBackground();
  }

  /// background page
  void initBackground() async {
    final image = await const
    NetworkImage("https://images.unsplash.com/photo-1604147706283-d7119b5b822c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MXx8YmxhbmslMjBhbmQlMjB3aGl0ZXxlbnwwfHwwfHw%3D&w=1000&q=80").image;
    setState(() {
      backgroundImage = image;
      controller.background = image.backgroundDrawable;
    });
  }

  /// Updates UI when the focus changes
  void onFocus() {setState(() {});}

  @override
  Widget build(BuildContext context) {
    return buildDefault(context);
  }

  /// body
  Widget buildDefault(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, kToolbarHeight),
        child: ValueListenableBuilder<PainterControllerValue>(
            valueListenable: controller,
            child: const Text("Flutter Painter Example"),
            builder: (context, _, child) {
              return AppBar(
                title: child,
                actions: [
                  /// Delete the selected drawable
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.trash,
                    ),
                    onPressed: controller.selectedObjectDrawable == null ? null : removeSelectedDrawable,
                  ),
                  /// Delete the selected drawable
                  IconButton(
                    icon: const Icon(
                      Icons.flip,
                    ),
                    onPressed: controller.selectedObjectDrawable != null && controller.selectedObjectDrawable is ImageDrawable
                        ? flipSelectedImageDrawable : null,
                  ),
                  /// Redo action
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.arrowClockwise,
                    ),
                    onPressed: controller.canRedo ? redo : null,
                  ),
                  /// Undo action
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.arrowCounterClockwise,
                    ),
                    onPressed: controller.canUndo ? undo : null,
                  ),
                ],
              );
            }),
      ),
      /// new page or delete page
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: (){
          Fluttertoast.showToast(msg: "Deleted page!");
          Navigator.of(context, rootNavigator: true).pushReplacement(PageTransition(child: NewPage(), type: PageTransitionType.rightToLeft));
        },
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          if (backgroundImage != null)
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: backgroundImage!.width / backgroundImage!.height,
                  child: FlutterPainter(
                    controller: controller,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, _, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        color: Colors.blue.withOpacity(.2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.freeStyleMode != FreeStyleMode.none) ...[
                            const Divider(),
                            const Text("Free Style Settings"),
                            // Control free style stroke width
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Stroke Width")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 2,
                                      max: 25,
                                      value: controller.freeStyleStrokeWidth,
                                      onChanged: setFreeStyleStrokeWidth),
                                ),
                              ],
                            ),
                            if (controller.freeStyleMode == FreeStyleMode.draw)
                              Row(
                                children: [
                                  const Expanded(flex: 1, child: Text("Color")),
                                  // Control free style color hue
                                  Expanded(
                                    flex: 3,
                                    child: Slider.adaptive(
                                        min: 0,
                                        max: 359.99,
                                        value: HSVColor.fromColor(controller.freeStyleColor).hue,
                                        activeColor: controller.freeStyleColor,
                                        onChanged: setFreeStyleColor),
                                  ),
                                ],
                              ),
                          ],
                          if (textFocusNode.hasFocus) ...[
                            const Divider(),
                            const Text("Text settings"),
                            // Control text font size
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Font Size")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 8,
                                      max: 96,
                                      value: controller.textStyle.fontSize ?? 14,
                                      onChanged: setTextFontSize),
                                ),
                              ],
                            ),

                            // Control text color hue
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Color")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 0,
                                      max: 359.99,
                                      value: HSVColor.fromColor(controller.textStyle.color ?? red).hue,
                                      activeColor: controller.textStyle.color,
                                      onChanged: setTextColor),
                                ),
                              ],
                            ),
                          ],
                          if (controller.shapeFactory != null) ...[
                            const Divider(),
                            const Text("Shape Settings"),

                            // Control text color hue
                            Row(
                              children: [
                                const Expanded(
                                    flex: 1, child: Text("Stroke Width")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 2,
                                      max: 25,
                                      value: controller.shapePaint?.strokeWidth ?? shapePaint.strokeWidth,
                                      onChanged: (value) => setShapeFactoryPaint((controller.shapePaint ??
                                          shapePaint).copyWith(strokeWidth: value,))),
                                ),
                              ],
                            ),

                            // Control shape color hue
                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Color")),
                                Expanded(
                                  flex: 3,
                                  child: Slider.adaptive(
                                      min: 0,
                                      max: 359.99,
                                      value: HSVColor.fromColor((controller.shapePaint ?? shapePaint).color).hue,
                                      activeColor: (controller.shapePaint ?? shapePaint).color,
                                      onChanged: (hue) => setShapeFactoryPaint((controller.shapePaint ?? shapePaint).copyWith(
                                        color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),))
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                const Expanded(flex: 1, child: Text("Fill shape")),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Switch(
                                        value: (controller.shapePaint ?? shapePaint).style == PaintingStyle.fill,
                                        onChanged: (value) => setShapeFactoryPaint((controller.shapePaint ?? shapePaint).copyWith(
                                          style: value ? PaintingStyle.fill : PaintingStyle.stroke,
                                        ))),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// Free-style drawing
            IconButton(
              icon: Icon(
                PhosphorIcons.paintRoller,
                color: controller.freeStyleMode == FreeStyleMode.draw ? Theme.of(context).accentColor : null,
              ),
              onPressed: toggleFreeStyleDraw,
            ),
            /// Add text
            IconButton(
              icon: Icon(
                PhosphorIcons.textT,
                color: textFocusNode.hasFocus ? Theme.of(context).accentColor : null,
              ),
              onPressed: addText,
            ),
            /// Add sticker image
            IconButton(
              icon: const Icon(
                PhosphorIcons.plus,
              ),
              onPressed: addCustomImage,
            ),

          ],
        ),
      ),
    );
  }

  /// add image
  void addCustomImage() async{
    if (controller.freeStyleMode != FreeStyleMode.none) {
      controller.freeStyleMode = FreeStyleMode.none;
    }
    chooseImage(context);
  }

  /// undo
  void undo() {
    controller.undo();
  }

  /// redo
  void redo() {
    controller.redo();
  }

  void toggleFreeStyleDraw() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.draw ? FreeStyleMode.draw : FreeStyleMode.none;
  }

  void toggleFreeStyleErase() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.erase
        ? FreeStyleMode.erase : FreeStyleMode.none;
  }

  /// write text
  void addText() {
    if (controller.freeStyleMode != FreeStyleMode.none) {
      controller.freeStyleMode = FreeStyleMode.none;
    }
    controller.addText();
  }

  void setFreeStyleStrokeWidth(double value) {
    controller.freeStyleStrokeWidth = value;
  }

  void setFreeStyleColor(double hue) {
    controller.freeStyleColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
  }

  void setTextFontSize(double size) {
    setState(() {
      controller.textSettings = controller.textSettings.copyWith(textStyle: controller.textSettings.textStyle.copyWith(fontSize: size));
    });
  }

  void setShapeFactoryPaint(Paint paint) {
    setState(() {
      controller.shapePaint = paint;
    });
  }

  void setTextColor(double hue) {
    controller.textStyle = controller.textStyle.copyWith(color: HSVColor.fromAHSV(1, hue, 1, 1).toColor());
  }

  /// remove item
  void removeSelectedDrawable() {
    final selectedDrawable = controller.selectedObjectDrawable;
    if (selectedDrawable != null) controller.removeDrawable(selectedDrawable);
  }

  void flipSelectedImageDrawable() {
    final imageDrawable = controller.selectedObjectDrawable;
    if (imageDrawable is! ImageDrawable) return;
    controller.replaceDrawable(imageDrawable, imageDrawable.copyWith(flipped: !imageDrawable.flipped));
  }

  /// image picker
  Future chooseImage(BuildContext context) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            Container(
              child: const Text(
                "Choose Photo",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey,
              margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  child: const SizedBox(
                    height: 90,
                    width: 90,
                    child: Icon(
                      Icons.photo,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    takeFromGallery();
                  },
                ),
                InkWell(
                  child: const SizedBox(
                    height: 90,
                    width: 90,
                    child: Icon(
                      Icons.camera,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    takeFromCamera();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// tack from gallery
  final ImagePicker picker = ImagePicker();
  File? filePhoto;
  Future takeFromGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() async{
        filePhoto = File(image.path);
        log("check_image_gallery: ${filePhoto?.path.toString()}");
        controller.addImage(await FileImage(filePhoto!).image, const Size(200, 200));
      });
    }
  }

  /// take from camera
  Future takeFromCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() async {
        filePhoto = File(image.path);
        log("check_image_camera: ${filePhoto?.path.toString()}");
        controller.addImage(await FileImage(filePhoto!).image, const Size(200, 200));
      });
    }
  }

}

