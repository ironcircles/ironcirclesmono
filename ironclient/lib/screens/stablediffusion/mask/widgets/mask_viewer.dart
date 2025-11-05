import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
// import 'package:image_selection_to_bw_image/draft/utils/dimensions.dart';
// import 'package:image_selection_to_bw_image/draft/utils/image_utils.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/mask_generator.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';

/// `MaskPreviewer` is a stateless widget that displays an image from memory within a square container.
/// It takes an optional `imageBytes` parameter of type `Uint8List?`, which contains the bytes of the image to display.
/// If `imageBytes` is null, the widget simply renders an empty container with specified dimensions.
///
/// The container's size is determined by `Dimensions.getSquareSize(context)`, ensuring it remains square across different devices.
/// If `imageBytes` is provided, the image is displayed with `Image.memory`, centered and scaled to fit within the container without stretching or cropping, using `BoxFit.contain`.
///
/// This widget is primarily used for previewing images that are dynamically loaded or manipulated in memory, such as masks or edited images in graphics applications.
///
/// Example usage:
/// MaskPreviewer(imageBytes: yourImageBytes)
/// This will render the image from the provided bytes within a blue-bordered square container.
class MaskPreviewer extends StatelessWidget {
  final Uint8List? imageBytes;
  final ImageDetails imageDetails;
  const MaskPreviewer({required this.imageDetails, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    double W = MediaQuery.of(context).size.width;
    double H = MediaQuery.of(context).size.height-ScreenSizes.maskPreviewToolbar;
    Offset imageScreenDimensions =MaskGenerator.calculateContainedImageDimensions(W,H,imageDetails.width.toDouble(),imageDetails.height.toDouble());


    if (imageBytes == null) return Container( width: imageScreenDimensions.dx,
      height: imageScreenDimensions.dy,);
//    ImageUtils.getImageDimensions(imageBytes!).then((value) => print("Dimensions "+value.toString()));

    return Container(
        decoration: BoxDecoration(
          //color: Colors.red,
          // border: Border.all(width: 1, color: Colors.blue)
        ),
        width: imageScreenDimensions.dx,
        height: imageScreenDimensions.dy,
        child:
        Image.memory(
          imageBytes!,
          alignment:Alignment.center ,
          width: imageScreenDimensions.dx,
          height: imageScreenDimensions.dy,
          fit: BoxFit.contain,

        ));
  }
}