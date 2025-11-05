import 'package:flutter/material.dart';
import 'package:ironcirclesapp/constants/constants.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
//import 'package:image_selection_to_bw_image/draft/utils/dimensions.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/logic/mask_generator.dart';
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/image_details.dart';

/// `ImageViewer` is a stateless widget designed to display an image within a square container.
/// It takes a mandatory `imageUrl` parameter, which specifies the URL of the image to be displayed.
/// The size of the viewer is dynamically determined by `Dimensions.getSquareSize(context)`, ensuring that
/// the image container remains square regardless of the screen dimensions.
///
/// This widget is styled with a linear gradient background ranging from grey to a darker shade of grey,
/// bordered with a blue line. The image is fetched from the network and displayed with `Image.network`.
/// It ensures that the image is centered and fits within the bounds of the square container without stretching
/// or cropping, using `BoxFit.contain`.
///
/// Usage example:
/// ImageViewer(imageUrl: 'https://example.com/path/to/image.jpg')
/// This will render a square image viewer with the image from the provided URL, adapting to the context's size constraints.
class ImageViewer extends StatelessWidget {
  final ImageDetails imageDetails;

  const ImageViewer({required this.imageDetails});

  @override
  Widget build(BuildContext context) {
    double W = MediaQuery.of(context).size.width;
    double H = MediaQuery.of(context).size.height-ScreenSizes.maskPreviewToolbar;
    Offset imageScreenDimensions =MaskGenerator.calculateContainedImageDimensions(W,H,imageDetails.width.toDouble(),imageDetails.height.toDouble());

    return Container(
        decoration: BoxDecoration(
          color: globalState.theme.inactiveThumbColor, //Colors.blue,
          gradient: LinearGradient(
              colors: [Colors.grey,Colors.grey.shade700],begin: Alignment.topCenter,end: Alignment.bottomCenter),
        ),
        width: imageScreenDimensions.dx,
        height: imageScreenDimensions.dy,
        child:  Image.file(
          imageDetails.file,
          alignment:Alignment.center ,
          width: imageScreenDimensions.dx,
          height: imageScreenDimensions.dy,
          fit: BoxFit.contain,
        ));
  }
}