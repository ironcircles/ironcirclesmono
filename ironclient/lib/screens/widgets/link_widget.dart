import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/link.dart';
import 'package:provider/provider.dart';

//version of thumbnail widget but for library links instead of library gallery
class LinkWidget extends StatefulWidget {
  final CircleObject? circleObject;
  final List<CircleObject>? libraryObjects;
  final bool isSelected;
  final bool anythingSelected;
  final Function longPress;
  final Function shortPress;
  final bool isSelecting;

  const LinkWidget(
      {this.circleObject,
      this.libraryObjects,
      required this.isSelected,
      required this.anythingSelected,
      required this.longPress,
      required this.shortPress,
      required this.isSelecting});

  @override
  LinkWidgetState createState() => LinkWidgetState();
}

class LinkWidgetState extends State<LinkWidget> {
  late GlobalEventBloc _globalEventBloc;
  final CircleBloc _circleBloc = CircleBloc();
  Circle? _circle;

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);

    //Listen for the first CircleObject load
    _globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        setState(() {
          //loaded = true;
        });
      }
    }, onError: (err) {
      debugPrint("CircleLinkUserWidget.initState: $err");
    }, cancelOnError: false);

    _circleBloc.fetchedResponse.listen((circle) {
      if (mounted) {
        if (_circle == null) {
          setState(() {
            _circle = circle;
          });
        }
      }
    }, onError: (err) {
      debugPrint("ThumbnailWidget.listen: $err");
    }, cancelOnError: false);

    super.initState();
  }

  //Need container to hold link, which can change appearance when selected
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: InkWell(
            onLongPress: () {
              widget.longPress(widget.circleObject);
            },
            onTap: () {
              widget.shortPress(widget.circleObject, _circle);
            },
            child: Padding(
                padding: const EdgeInsets.all(0), //widget.isSelected ? 1: 0
                child: Stack(children: [
                  Link(
                    //width: 400, //400
                    circleObject: widget.circleObject!,
                  ),
                  Positioned.fill(
                      child: Container(
                    color: widget.isSelected
                        ? const Color.fromRGBO(124, 252, 0, 0.5)
                        : Colors.transparent,
                    alignment: Alignment.center,
                  )),
                  widget.isSelected
                      ? Padding(
                          padding: const EdgeInsets.all(0), //5
                          child: Icon(
                            Icons.check_circle,
                            color: globalState.theme.buttonIcon,
                          ))
                      : widget.anythingSelected
                          ? Padding(
                              padding: const EdgeInsets.all(0),
                              child: Icon(
                                Icons.circle_outlined,
                                color: globalState.theme.buttonIcon,
                              ))
                          : Container(),
                ]))));
  }
}
