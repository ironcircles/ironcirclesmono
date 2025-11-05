import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circle_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
//import 'package:ironcirclesapp/screens/widgets/recipe.dart';

import 'package:ironcirclesapp/models/export_models.dart';
import 'package:provider/provider.dart';

//version of thumbnail widget but for library links instead of library gallery
class RecipeWidget extends StatefulWidget {
  final CircleObject? circleObject;
  final List<CircleObject>? libraryObjects;
  final bool isSelected;
  final bool anythingSelected;
  final Function longPress;
  final Function shortPress;
  final bool isSelecting;

  const RecipeWidget(
      {this.circleObject,
        this.libraryObjects,
        required this.isSelected,
        required this.anythingSelected,
        required this.longPress,
        required this.shortPress,
        required this.isSelecting});

  @override
  RecipeWidgetState createState() => RecipeWidgetState();
}

class RecipeWidgetState extends State<RecipeWidget> {
  //late RecipeBloc _recipeBloc;
  late GlobalEventBloc _globalEventBloc;
  CircleBloc _circleBloc = CircleBloc();
  Circle? _circle;

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  void initState() {
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    //_recipeBloc = RecipeBloc(); //_globalEventBloc

    //Listen for the first CircleObject load
    _globalEventBloc.progressIndicator.listen((circleObject) {
      if (mounted) {
        setState(() {
          //loaded = true;
        });
      }
    }, onError: (err) {
      debugPrint("CircleRecipeUserWidget.initState: $err");
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

    // _linkBloc(
    //   widget.circleObject!.userFurnace!,
    //   widget.circleObject!.userCircleCache!,
    //   widget.circleObject!,
    //   CircleObjectBloc(globalEventBloc: _globalEventBloc));
    super.initState();
  }

  //Need container to hold link, which can change appearance when selected
  @override
  Widget build(BuildContext context) {

    ListTile makeListTile(CircleObject object) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
      leading: Container(
        padding: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
            border: Border(
                right: BorderSide(
                    width: 1.0, color: globalState.theme.cardSeparator))),
        child: Icon(Icons.restaurant,
            color: globalState.theme.cardLeadingIcon),
      ),
      title: Container(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          object.recipe!.name!, textScaler: TextScaler.linear(globalState.cardScaleFactor),
          //circleObject.userFurnace.alias,
          style: TextStyle(
              color: globalState.theme.cardTitle,
              fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: Column(children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
                flex: 0,
                child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                    child: Text(
                      object.userFurnace!.alias!,  textScaler: TextScaler.linear(globalState.cardScaleFactor),
                      style: TextStyle(color: globalState.theme.furnace),
                    ))),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
                flex: 3,
                child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                    child: Text(
                      "Circle: ",  textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(color: globalState.theme.cardLabel),
                    ))),
            Expanded(
                flex: 8,
                child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, bottom: 5, top: 10),
                    child: Text(
                      object.userCircleCache!.prefName!,  textScaler: TextScaler.linear(globalState.cardScaleFactor),
                      style: TextStyle(color: globalState.theme.textTitle),
                    ))),
          ],
        ),
      ]),
      trailing: Icon(Icons.keyboard_arrow_right,
          color: globalState.theme.cardTrailingIcon, size: 30.0),
      // onTap: () {
      //   //openDetail(context, userFurnace);
      //   _tapHandler(index, object);
      // },
    );


    return Expanded(
        child:InkWell(
            onLongPress: () {
              widget.longPress(widget.circleObject);
            },
            onTap: () {
              widget.shortPress(widget.circleObject, _circle);
            },
            child: Padding(
                padding: const EdgeInsets.all(0), //widget.isSelected ? 1: 0
                child: Stack(children: [
                  Container(
                    width: 400,
                    child: makeListTile(widget.circleObject!),
                    // child: Link(
                    //   width: 400, //400
                    //   circleObject:
                    //   widget.circleObject!,
                    // ),
                  ),
                  widget.isSelected
                      ? Container(
                    color: const Color.fromRGBO(124,252, 0, 0.5),
                    alignment: Alignment.center,
                    width: 400,
                  )
                      : Container(),
                  widget.isSelected
                      ? Padding(
                      padding: const EdgeInsets.all(0), //5
                      child: Icon(
                        Icons.check_circle,
                        color: globalState.theme.buttonIcon,
                      ))
                  // : widget.anythingSelected
                  // ? Padding(
                  //   padding: EdgeInsets.all(5),
                  //   child: Icon(
                  //     Icons.circle_outlined,
                  //     color: globalState.theme.buttonDisabled,
                  //   ))
                      : Container(),
                  // widget.circleObject!.circle!.id == DeviceOnlyCircle.circleID
                  //   ? Align(
                  //     alignment: Alignment.bottomRight,
                  //     child: Padding(
                  //       padding: EdgeInsets.all(5),
                  //       child: Icon(
                  //         Icons.save,
                  //         color: globalState.theme.buttonIconHighlight,
                  //       )))
                  //     : Container(),

                ])))
    );
  }
}
