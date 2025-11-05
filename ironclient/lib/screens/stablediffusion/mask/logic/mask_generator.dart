import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:ironcirclesapp/screens/stablediffusion/mask/enum/tool_type.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/SelectionWithTool.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/utils/dimensions.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/utils/image_utils.dart';

class MaskGenerator {
  static Future<Uint8List> generateMask(
      BuildContext context,
      List<SelectionWithTool> screenPointsWithTool,
      ImageDetails imageDetails) async {
    debugPrint("Generating mask...");
    debugPrint(
        " * Dimensions             :  ${imageDetails.width} x ${imageDetails.height}");
    debugPrint(
        " * Stroke count           :  ${screenPointsWithTool.map((c) => c.screenPoints.length).toList().reduce((value, element) => value + element)}");

    Stopwatch stopwatch = Stopwatch()..start();
    Stopwatch stopwatch1 = Stopwatch()..start();

    double W = Dimensions.getScreenWidth(context);
    double H = Dimensions.getScreenHeight(context);
    double ratio = screenToImageRatio2(
        W, H, imageDetails.width.toDouble(), imageDetails.height.toDouble());

    ///create background
    img.Image result =
        await createEmptyImage(imageDetails.width, imageDetails.height);

    debugPrint(" * Step 1 Creating canvas : ${stopwatch1.elapsedMilliseconds}ms");
    Stopwatch stopwatch2 = Stopwatch()..start();

    //     final testMask = MaskGenerator.createRectangleImage(imageDetails.width, imageDetails.height, [
//       Offset(0, 0),
// Offset(imageDetails.width.toDouble()-10,imageDetails.height.toDouble()-10)
// //      Offset(imageScreenDimensions.dx,imageScreenDimensions.dy)
//     ]);
//     result = ImageUtils.additiveBlend(result, testMask);

    //generate mask stroke by stroke, depending on which tool was used
    // if(false)
    Stopwatch stopwatch4 = Stopwatch();
    Stopwatch stopwatch5 = Stopwatch();
    for (var selection in screenPointsWithTool) {
      if (selection.screenPoints.isNotEmpty) {
        //scale screenPoints to imagePoints
        final imagePoints = scalePoints2(
            imageDetails,
            selection.screenPoints,
            W,
            H,
            imageDetails.width.toDouble(),
            imageDetails.height.toDouble());

        switch (selection.tool) {
          case ToolType.circle_brush:
            final screenBrushRadius = selection.toolRadius ?? 10.0;
            final brushRadius = screenBrushRadius / ratio;
            stopwatch4.start();
            final strokeMask = await createCircleBrushImage(imageDetails.width,
                imageDetails.height, imagePoints, brushRadius);
            stopwatch4.stop();
            stopwatch5.start();
            result = ImageUtils.additiveBlend(result, strokeMask);
            stopwatch5.stop();
            break;
          case ToolType.lasso:
            final strokeMask = createLassoImage(
                imageDetails.width, imageDetails.height, imagePoints);
            result = ImageUtils.additiveBlend(result, strokeMask);
            break;
          case ToolType.rect_area:
            final strokeMask = createRectangleImage(
                imageDetails.width, imageDetails.height, imagePoints);
            result = ImageUtils.additiveBlend(result, strokeMask);
            break;
          default:
        }
      }
    }
    debugPrint(" * Step 2 Painting        : ${stopwatch2.elapsedMilliseconds}ms");
    debugPrint("      -  2a Brushing      : ${stopwatch4.elapsedMilliseconds}ms");
    debugPrint("      -  2b Blending      : ${stopwatch5.elapsedMilliseconds}ms");

    Stopwatch stopwatch3 = Stopwatch()..start();
    Uint8List imageBytes1 = encodeImageToUint8List(result);

    debugPrint(" * Step 3 Encoding        : ${stopwatch3.elapsedMilliseconds}ms");

    stopwatch.stop();
    debugPrint(" * TOTAL                  : ${stopwatch.elapsedMilliseconds}ms");
    return imageBytes1;
  }

  /// Scales a list of points from screen coordinates to image coordinates based on the dimensions of the image and the size of the viewer.
  /// The function takes an [ImageDetails] object containing the image's width and height, a list of [Offset] points ([screenPoints_]) defined in screen coordinates, and the size of the viewer ([viewerSize]) in which the image is displayed. It returns a new list of [Offset] points scaled to match the dimensions of the image.
  /// This scaling is particularly useful for converting touch or pointer locations on the screen to corresponding points on the original image, allowing for operations like cropping or annotations to be accurately applied to the image itself.
  /// [imageDetails]: The details of the image, including its width and height.
  /// [screenPoints_]: The points on the screen to be scaled, expressed as a list of [Offset] objects.
  /// [viewerSize]: The size of the viewer area (e.g., an image viewer widget) in which the image is being displayed.
  static List<Offset> scalePoints(ImageDetails imageDetails,
      List<Offset> screenPoints_, double viewerSize) {
    List<Offset> imagePoints = [];
    for (var k in screenPoints_) {
      final ratio = getScreenToImageRatio(imageDetails, viewerSize);
      final dx = k.dx * ratio;
      final dy = k.dy * ratio;
      final scaledPosition = Offset(dx, dy);
      imagePoints.add(scaledPosition);
    }
    return imagePoints;
  }

  static double getScreenToImageRatio(
      ImageDetails imageDetails, double viewerSize) {
    final size = imageDetails.width < imageDetails.height
        ? imageDetails.height
        : imageDetails.width;
    final ratio = size / viewerSize;
    return ratio;
  }

  static double getScreenToImageRatioFromContext(
      ImageDetails imageDetails, BuildContext context) {
    final viewerSize = Dimensions.getSquareSize(context);
    final size = imageDetails.width < imageDetails.height
        ? imageDetails.height
        : imageDetails.width;
    final ratio = size / viewerSize;
    return ratio;
  }

  static Offset calculateContainedImageDimensions(double screenWidth,
      double screenHeight, double imgWidth, double imgHeight) {
    // Calculate aspect ratios
    double screenAR = screenWidth / screenHeight;
    double imgAR = imgWidth / imgHeight;

    double scaledWidth, scaledHeight;

    // Determine whether the image is limited by width or height
    if (imgAR > screenAR || imgAR > screenHeight) {
      // Image is wider than the screen, so it is limited by width
      scaledWidth = screenWidth;
      scaledHeight = screenWidth / imgAR; // Maintain the aspect ratio
    } else {
      // Image is taller than the screen, so it is limited by height
      scaledHeight = screenHeight;
      scaledWidth = screenHeight * imgAR; // Maintain the aspect ratio
    }

    return Offset(scaledWidth, scaledHeight);
  }

  static bool isLimitedByWidth(double screenWidth, double screenHeight,
      double imgWidth, double imgHeight) {
    // Calculate aspect ratios
    double screenAR = screenWidth / screenHeight;
    double imgAR = imgWidth / imgHeight;

    // Determine whether the image is limited by width or height
    if (imgAR > screenAR) {
      return true;
    } else {
      return false;
    }
  }

  static Offset findImagePosition(double screenWidth, double screenHeight,
      double imgWidth, double imgHeight) {
    // Calculate aspect ratios
    double screenAR = screenWidth / screenHeight;
    double imgAR = imgWidth / imgHeight;

    double posX, posY, scaledWidth, scaledHeight;

    // Determine whether the image is limited by width or height
    if (imgAR > screenAR) {
      // Image limited by width
      scaledWidth = screenWidth;
      scaledHeight = scaledWidth; // / imgAR;

      posX = 0; // Image spans the entire width
      posY = (screenHeight - scaledHeight) / 2; // Center vertically
    } else {
      // Image limited by height
      scaledHeight = screenHeight;
      scaledWidth = scaledHeight; // * imgAR;

      posY = 0; // Image spans the entire height
      posX = (screenWidth - scaledWidth) / 2; // Center horizontally
    }

    return Offset(posX, posY);
  }

  /// Encodes an [img.Image] object into a [Uint8List] byte array in the specified image format.
  /// This function allows for the encoding of an image into a byte array, supporting 'png' and 'jpeg' formats.
  /// It is useful for converting images processed or generated within the app into a format that can be easily saved, shared, or displayed in Flutter widgets.
  /// [image]: The [img.Image] object to be encoded.
  /// [format]: Optional. The format in which the image should be encoded. Defaults to 'png'.
  ///           If any format other than 'png' is specified, the image will be encoded in 'jpeg'.
  /// Returns a [Uint8List] containing the bytes of the encoded image.
  static Uint8List encodeImageToUint8List(img.Image image,
      {String format = 'png'}) {
    List<int> bytes;
    if (format == 'png') {
      bytes = img.encodePng(image);
    } else {
      // Defaults to JPEG if not PNG
      bytes = img.encodeJpg(image);
    }
    return Uint8List.fromList(bytes);
  }

  static img.Color getBlack() {
    return img.ColorRgb8(0, 0, 0);
  }

  static img.Color getWhite() {
    return img.ColorRgb8(255, 255, 255);
  }

  static img.Image getEmptyMask(int width, int height) {
    img.Image image = img.Image(width: width, height: height);
    img.fill(image, color: getBlack()); // Fill the image
    return image;
  }

  static double screenToImageRatio(double screenWidth, double screenHeight,
      double imgWidth, double imgHeight) {
    // Calculate aspect ratios
    double screenAR = screenWidth / screenHeight;
    double imgAR = imgWidth / imgHeight;

    // Determine the limiting dimension based on aspect ratio comparison
    if (imgAR > screenAR) {
      // Image is wider than the screen, limited by width
      double scale = screenWidth / imgWidth;
      return screenHeight / (imgHeight * scale);
    } else {
      // Image is taller than the screen, limited by height
      double scale = screenHeight / imgHeight;
      return screenWidth / (imgWidth * scale);
    }
  }

  static double screenToImageRatio2(double screenWidth, double screenHeight,
      double imgWidth, double imgHeight) {
    // Calculate aspect ratios
    double screenAR = screenWidth / screenHeight;
    double imgAR = imgWidth / imgHeight;

    // Determine the limiting dimension based on aspect ratio comparison
    if (imgAR > screenAR) {
      // Image is wider than the screen, limited by width
      double scale = screenWidth / imgWidth;
      return scale;
    } else {
      // Image is taller than the screen, limited by height
      double scale = screenHeight / imgHeight;
      return scale; //reenWidth / (imgWidth * scale);
    }
  }

  static List<Offset> scalePoints2(
      ImageDetails imageDetails,
      List<Offset> screenPoints_,
      double screenWidth,
      double screenHeight,
      double viewerWidth,
      double viewerHeight) {
    List<Offset> imagePoints = [];
    final ratio = screenToImageRatio2(screenWidth, screenHeight, viewerWidth,
        viewerHeight); //getScreenToImageRatio(imageDetails,viewerSize);
    //  final imagePosition=findImagePosition(screenWidth,screenHeight, viewerWidth,viewerHeight);
    // print("RATIO W=$screenWidth H=$screenHeight w=$viewerWidth h=$viewerHeight r=$ratio");
    // print("POS W=$screenWidth H=$screenHeight w=$viewerWidth h=$viewerHeight dx=${imagePosition.dx} dy=${imagePosition.dy}");
    for (var k in screenPoints_) {
      // final dx2=k.dx-imagePosition.dx;
      // final dy2=k.dy-imagePosition.dy;
      final dx2 = k.dx;
      final dy2 = k.dy;

      final dx = dx2 / ratio;
      final dy = dy2 / ratio;

      // final dx2=dx-imagePosition.dx;
      // final dy2=dy-imagePosition.dy;
      final scaledPosition = Offset(dx, dy);
      imagePoints.add(scaledPosition);
      //   print(k.dx.toInt().toString()+" "+k.dy.toInt().toString()+" -> ("+dx.toInt().toString()+" "+dy.toInt().toString()+") "+" -> "+dx2.toString()+" "+dy2.toString()+" ");
    }
    return imagePoints;
  }

  /// Creates a black and white image of the specified dimensions and draws white circles at the specified center points.
  /// This function generates a new image filled with black and then iterates over a list of [Offset] points, drawing white circles at each point. After drawing the circles, the entire image is converted to grayscale (black and white), which in this context, should not significantly change the appearance since the image is initially filled with black and the circles are white.
  /// [width]: The width of the generated image.
  /// [height]: The height of the generated image.
  /// [circleCenters]: A list of [Offset] objects representing the center points of the circles to be drawn.
  /// Returns a [Future<img.Image>] that resolves to the generated image with the applied modifications.
  /// Throws an exception if the image cannot be generated or if invalid dimensions are provided.
  static Future<img.Image> createCircleBrushImage(int width, int height,
      List<Offset> circleCenters, double imageBrushRadius) async {
    // Load the image
    img.Image image = getEmptyMask(width, height); // Fill the image with black
    if (image == null) {
      throw Exception("Failed to decode image");
    }

    final radius = imageBrushRadius.toInt(); //(0.028*size).toInt();

    for (var center in circleCenters) {
      final x0 = center.dx.toInt();
      final y0 = center.dy.toInt();

      ///check circumference and boundaries
      if (radius < 0) {
      } else if (x0 - radius >= image.width) {
      } else if (y0 + radius < 0) {
      } else if (y0 - radius >= image.height) {
      } else {
        img.fillCircle(image, x: x0, y: y0, radius: radius, color: getWhite());
      }
    }

    // Convert to black and white
    img.grayscale(image);

    return image;
  }

  static img.Image createOutlinedLassoImage(
      int width, int height, List<Offset> points) {
    // Create an empty image with a black background
    img.Image image = getEmptyMask(width, height); // Fill the image with black

    // Ensure there are enough points to form a polygon
    if (points.length < 3) return image;

    // Draw white lines between each pair of points to form the polygon outline
    for (int i = 0; i < points.length - 1; i++) {
      img.drawLine(image,
          x1: points[i].dx.toInt(),
          y1: points[i].dy.toInt(),
          x2: points[i + 1].dx.toInt(),
          y2: points[i + 1].dy.toInt(),
          color: getWhite());
    }

    // Connect the last point back to the first to close the polygon
    img.drawLine(image,
        x1: points.last.dx.toInt(),
        y1: points.last.dy.toInt(),
        x2: points.first.dx.toInt(),
        y2: points.first.dy.toInt(),
        color: getWhite());

    return image;
  }

  static img.Image createRectangleImage(
      int width, int height, List<Offset> points) {
    // Create an empty image with a black background
    img.Image image = getEmptyMask(width, height); // Fill the image with black
    final bounds = ImageUtils.getRectangleEnvelope(
        points); // Initialize min and max values with the first point

    img.fillRect(image,
        x1: bounds.minX.toInt(),
        y1: bounds.minY.toInt(),
        x2: bounds.maxX.toInt(),
        y2: bounds.maxY.toInt(),
        color: getWhite());

    return image;
  }

  static img.Image createLassoImage(
      int width, int height, List<Offset> points) {
    // Create an empty image with a black background
    img.Image image = getEmptyMask(width, height); // Fill the image with black

    // Convert Offset points to a list of integers for the image package
    List<img.Point> imgPoints = [];
    for (var point in points) {
      imgPoints.add(img.Point(point.dx.toInt(), point.dy.toInt()));
    }

    // Draw a white polygon based on the provided points
    img.fillPolygon(image, vertices: imgPoints, color: getWhite());

    // Ideally, you would fill this polygon to create a solid white area.
    // As a workaround for filling, consider using an algorithm to determine
    // the inside of the polygon and manually setting pixels or use external
    // tools or libraries capable of filling shapes in raster graphics.

    return image;
  }

  /// Creates a black and white image of the specified dimensions
  /// This function generates a new image filled with black
  /// [width]: The width of the generated image.
  /// [height]: The height of the generated image.
  /// Returns a [Future<img.Image>] that resolves to the generated image with the applied modifications.
  /// Throws an exception if the image cannot be generated or if invalid dimensions are provided.
  static Future<img.Image> createEmptyImage(int width, int height) async {
    // Load the image
    img.Image image = getEmptyMask(width, height); // Fill the image with black

    if (image == null) {
      throw Exception("Failed to decode image");
    }

    return image;
  }
}