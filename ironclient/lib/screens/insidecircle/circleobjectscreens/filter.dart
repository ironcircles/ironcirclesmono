// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'dart:ui';
//
// //import 'package:bitmap/bitmap.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:ironcirclesapp/models/globalstate.dart';
// import 'package:ironcirclesapp/models/mediatype.dart';
// import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
// import 'package:ironcirclesapp/services/cache/filesystem_service.dart';
// import 'package:ironcirclesapp/utils/fileutil.dart';
//
// class Filter extends StatefulWidget {
//   final File image;
//
//   const Filter({Key? key, required this.image}) : super(key: key);
//
//   @override
//   FilterState createState() => FilterState();
// }
//
// class FilterState extends State<Filter> {
//   final ScrollController _scrollController = ScrollController();
//   late MediaCollection _images = MediaCollection();
//   late Media _preview;
//   late TransformationController _transformationController;
//   double _heightWithScroller = 372;
//   double _heightWithScrollerHorizontal = 170;
//
//   final spinkit = SpinKitDualRing(
//     color: globalState.theme.spinner,
//     size: 40,
//   );
//
//   @override
//   void initState() {
//     _transformationController = TransformationController();
//
//     Media media = Media(
//       mediaType: MediaType.image,
//       path: widget.image.path,
//     );
//     _images.add(media);
//
//     _preview = media;
//
//     fullSetup();
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
//
//     final _scroller = Padding(
//         padding: const EdgeInsets.only(top: 0, bottom: 0),
//         child: Column(children: <Widget>[
//           SizedBox(
//               height: 100,
//               width: MediaQuery.of(context).size.width - 20,
//               child: Scrollbar(
//                   controller: _scrollController,
//                   thumbVisibility: true,
//                   child: ListView.builder(
//                       itemCount: 11, //_images.media.length,
//                       padding: const EdgeInsets.only(right: 0, left: 0),
//                       controller: _scrollController,
//                       scrollDirection: Axis.horizontal,
//                       itemBuilder: (BuildContext context, int index) {
//                         if (_images.media.length <= index) {
//                           return Container(
//                               width: 80, child: Center(child: spinkit));
//                         } else {
//                           return Padding(
//                               padding: const EdgeInsets.only(right: 10),
//                               child: InkWell(
//                                   onTap: () {
//                                     debugPrint('on tap');
//                                     setState(() {
//                                       _preview = _images.media[index];
//                                     });
//                                   },
//                                   child: ConstrainedBox(
//                                       constraints: const BoxConstraints(
//                                           maxHeight: 170, maxWidth: 250),
//                                       child: Image.file(
//                                         File(_images.media[index].path),
//                                         fit: BoxFit.cover,
//                                       ))));
//                         }
//                       })))
//         ]));
//
//     final _makePreview = Stack(alignment: Alignment.topRight, children: [
//       Column(children: [
//         ConstrainedBox(
//             constraints: BoxConstraints.expand(
//                 height: isPortrait
//                     ? MediaQuery.of(context).size.height - _heightWithScroller
//                     : MediaQuery.of(context).size.height -
//                         _heightWithScrollerHorizontal),
//             child: InteractiveViewer(
//                 transformationController: _transformationController,
//                 minScale: 0.1,
//                 maxScale: 5,
//                 child: Image.file(
//                   File(_preview.path),
//                   fit: BoxFit.contain,
//                 )))
//       ])
//     ]);
//
//     final topAppBar = ICAppBar(
//       title: AppLocalizations.of(context)!.filter,
//     );
//
//     return Scaffold(
//       backgroundColor: globalState.theme.background,
//       resizeToAvoidBottomInset: false,
//       //key: _scaffoldKey,
//       appBar: topAppBar,
//       body: SafeArea(
//           left: false,
//           top: false,
//           right: true,
//           bottom: true,
//           child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: <Widget>[
//                 Expanded(child: _makePreview),
//                 const Padding(padding: EdgeInsets.only(bottom: 12)),
//                 _scroller,
//               ])),
//       floatingActionButton: FloatingActionButton(
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(30.0))),
//         onPressed: _cacheFilter,
//         backgroundColor: globalState.theme.background,
//         child: Icon(Icons.check_circle,
//             size: 45, color: globalState.theme.buttonIcon),
//       ),
//     );
//   }
//
//   _cacheFilter() async {
//     Uint8List? bytes = File(_preview.path).readAsBytesSync();
//
//     String filePath = await FileSystemService.returnTempPathAndImageFile();
//     File? file = await FileUtil.writeBytesToFile(filePath, bytes);
//
//     Navigator.pop(context, file);
//   }
//
//   Future<File?> _writeToFile(Uint8List data) async {
//     String filePath = await FileSystemService.returnTempPathAndImageFile();
//
//     File? file = await FileUtil.writeBytesToFile(filePath, data);
//     return file;
//   }
//
//   ByteData _readFromFile(File file) {
//     Uint8List bytes = file.readAsBytesSync();
//     return ByteData.view(bytes.buffer);
//   }
//
//   _loadImageSource(File source) async {
//     ByteData data = _readFromFile(source);
//     ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
//     ui.FrameInfo fi = await codec.getNextFrame();
//     return fi.image;
//   }
//
//   fullSetup() async {
//     File? red = await setup(widget.image, Colors.red, BlendMode.hue, null);
//
//     ///red
//     Media redMedia = Media(
//       mediaType: MediaType.image,
//       path: red!.path,
//     );
//     setState(() {
//       _images.add(redMedia);
//     });
//     File? blue = await setup(widget.image, Colors.blue, BlendMode.hue, null);
//
//     ///blue
//     Media blueMedia = Media(
//       mediaType: MediaType.image,
//       path: blue!.path,
//     );
//     setState(() {
//       _images.add(blueMedia);
//     });
//     File? enhance =
//         await setup(widget.image, Colors.red, BlendMode.saturation, null);
//
//     ///enhance existing color
//     Media enhanceMedia = Media(
//       mediaType: MediaType.image,
//       path: enhance!.path,
//     );
//     setState(() {
//       _images.add(enhanceMedia);
//     });
//     File? mono = await setup(widget.image, Colors.white, BlendMode.hue, null);
//
//     ///black and white
//     Media monoMedia = Media(
//       mediaType: MediaType.image,
//       path: mono!.path,
//     );
//     setState(() {
//       _images.add(monoMedia);
//     });
//     File? amber = await setup(widget.image, Colors.amber, BlendMode.hue, null);
//
//     ///amber
//     Media amberMedia = Media(
//       mediaType: MediaType.image,
//       path: amber!.path,
//     );
//     setState(() {
//       _images.add(amberMedia);
//     });
//     File? brown = await setup(widget.image, Colors.brown, BlendMode.hue, null);
//
//     ///brown
//     Media brownMedia = Media(
//       mediaType: MediaType.image,
//       path: brown!.path,
//     );
//     setState(() {
//       _images.add(brownMedia);
//     });
//     File? green = await setup(widget.image, Colors.green, BlendMode.hue, null);
//
//     ///green
//     Media greenMedia = Media(
//       mediaType: MediaType.image,
//       path: green!.path,
//     );
//     setState(() {
//       _images.add(greenMedia);
//     });
//     File? blur = await setup(widget.image, null, BlendMode.hue,
//         ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0));
//     Media blurMedia = Media(
//       mediaType: MediaType.image,
//       path: blur!.path,
//     );
//     setState(() {
//       _images.add(blurMedia);
//     });
//     File? dilate = await setup(widget.image, null, BlendMode.hue,
//         ImageFilter.dilate(radiusX: 10.0, radiusY: 10.0));
//     Media dilateMedia = Media(
//       mediaType: MediaType.image,
//       path: dilate!.path,
//     );
//     setState(() {
//       _images.add(dilateMedia);
//     });
//     File? erode = await setup(widget.image, null, BlendMode.hue,
//         ImageFilter.erode(radiusX: 10.0, radiusY: 10.0));
//     Media erodeMedia = Media(
//       mediaType: MediaType.image,
//       path: erode!.path,
//     );
//     setState(() {
//       _images.add(erodeMedia);
//     });
//   }
//
//   Future<File?> setup(File imageSource, Color? color, BlendMode blendMode,
//       ImageFilter? filter) async {
//     File? imageResult;
//     ui.Image image = await _loadImageSource(imageSource);
//
//     if (image != null) {
//       final recorder = ui.PictureRecorder();
//       var rect = Rect.fromPoints(const Offset(0.0, 0.0),
//           Offset(image.width.toDouble(), image.height.toDouble()));
//       final canvas = Canvas(recorder, rect);
//
//       Size outputSize = rect.size;
//       Paint paint = new Paint();
//
//       if (color != null) {
//         paint.colorFilter = ColorFilter.mode(color, blendMode);
//       } else {
//         paint.imageFilter = filter;
//       }
//
//       //Image
//       Size inputSize = Size(image.width.toDouble(), image.height.toDouble());
//       final FittedSizes fittedSizes =
//           applyBoxFit(BoxFit.contain, inputSize, outputSize);
//       final Size sourceSize = fittedSizes.source;
//       final Rect sourceRect =
//           Alignment.center.inscribe(sourceSize, Offset.zero & inputSize);
//
//       canvas.drawImageRect(image, sourceRect, rect, paint);
//
//       final picture = recorder.endRecording();
//       final img =
//           await picture.toImage(image.width.toInt(), image.height.toInt());
//
//       ByteData? byteData =
//           await img.toByteData(format: ui.ImageByteFormat.rawUnmodified);
//       Uint8List? byteDataList = byteData?.buffer.asUint8List();
//       Bitmap bitmap = Bitmap.fromHeadless(
//           image.width.toInt(), image.height.toInt(), byteDataList!);
//       Uint8List headedIntList = bitmap.buildHeaded();
//
//       imageResult = await _writeToFile(headedIntList);
//       return imageResult;
//     }
//     return null;
//   }
// }
