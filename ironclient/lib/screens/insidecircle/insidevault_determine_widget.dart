import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/circlealbum_bloc.dart';
import 'package:ironcirclesapp/blocs/circlefile_bloc.dart';
import 'package:ironcirclesapp/blocs/circleimage_bloc.dart';
import 'package:ironcirclesapp/blocs/circlelist_bloc.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/circlerecipe_bloc.dart';
import 'package:ironcirclesapp/blocs/circlevideo_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_bloc.dart';
import 'package:ironcirclesapp/blocs/videocontroller_desktop_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/calendar_holder.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/gallery_holder.dart';
import 'package:ironcirclesapp/screens/insidecircle/insidevault_widgets/vault_object_display.dart';

class InsideVaultDetermineWidget extends StatelessWidget {
  final UserCircleCache userCircleCache;
  final UserFurnace userFurnace;
  final Circle circle;
  final List<CircleObject> circleObjects;
  final List<CircleObject> memCacheObjects;

  final Future<void> Function() refresh;
  final bool Function(ScrollEndNotification) onNotification;

  ///final int index;
  final Function tapHandler;
  final Function shareObject;
  final Function unpinObject;
  final Function longPressHandler;
  final Function longReaction;
  final Function shortReaction;
  final Function storePosition;
  final Function copyObject;
  final Function reactionAdded;
  final Function showReactions;
  final bool displayReactionsRow;
  final VideoControllerBloc videoControllerBloc;
  final VideoControllerDesktopBloc videoControllerDesktopBloc;
  final CircleVideoBloc circleVideoBloc;
  final CircleRecipeBloc circleRecipeBloc;
  final CircleObjectBloc circleObjectBloc;
  final CircleImageBloc circleImageBloc;
  final GlobalEventBloc globalEventBloc;
  final CircleFileBloc circleFileBloc;
  final CircleAlbumBloc circleAlbumBloc;
  final Function updateList;
  final Function submitVote;
  final Function deleteObject;
  final Function editObject;
  final Function streamVideo;
  final Function downloadFile;
  final Function downloadVideo;
  final Function retry;
  final Function removeCache;
  final Function predispose;
  final Function playVideo;
  final Function openExternalBrowser;
  final Function leave;
  final Function export;
  final Function cancelTransfer;
  final Function populateVideoFile;
  final Function populateRecipeImageFile;
  final Function populateImageFile;
  final bool interactive;
  final bool reverse;
  final List<Member> members;
  //final Function refresh;
  final Function send;
  final Function sendLink;
  final Function captureMedia;
  final Function selectMedia;
  final Function pickFiles;
  final Function refreshObjects;
  final UserCircleBloc userCircleBloc;
  final CircleListBloc circleListBloc;
  final Function searchGiphy;
  final Function generateImage;

  //final Function selectVideos;

  //late IconData icon;

  const InsideVaultDetermineWidget({
    Key? key,
    required this.members,
    required this.reverse,
    required this.userCircleCache,
    required this.userFurnace,
    required this.circleObjects,
    required this.memCacheObjects,
    required this.captureMedia,
    required this.sendLink,
    //required this.selectVideos,
    required this.onNotification,
    required this.refresh,
    required this.searchGiphy,
    required this.generateImage,

    ///required this.index,
    required this.circle,
    required this.tapHandler,
    required this.shareObject,
    required this.unpinObject,
    required this.openExternalBrowser,
    required this.leave,
    required this.export,
    required this.cancelTransfer,
    required this.longPressHandler,
    required this.longReaction,
    required this.shortReaction,
    required this.storePosition,
    required this.copyObject,
    required this.reactionAdded,
    required this.showReactions,
    required this.videoControllerBloc,
    required this.videoControllerDesktopBloc,
    required this.circleAlbumBloc,
    required this.globalEventBloc,
    required this.circleVideoBloc,
    required this.circleObjectBloc,
    required this.circleImageBloc,
    required this.circleRecipeBloc,
    required this.circleFileBloc,
    required this.updateList,
    required this.submitVote,
    required this.deleteObject,
    required this.editObject,
    required this.streamVideo,
    required this.downloadVideo,
    required this.downloadFile,
    required this.retry,
    required this.predispose,
    required this.playVideo,
    required this.removeCache,
    required this.populateVideoFile,
    required this.populateRecipeImageFile,
    required this.populateImageFile,
    required this.displayReactionsRow,
    required this.interactive,
    required this.send,
    required this.selectMedia,
    required this.pickFiles,
    required this.refreshObjects,
    required this.userCircleBloc,
    required this.circleListBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (globalState.isDesktop()) {
      screenWidth = screenWidth / 3;
    }

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: InsideConstants.getVaultWidth(screenWidth, screenHeight),
      children: <Widget>[
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => GalleryHolder(
                        memCacheObjects: memCacheObjects,
                        refresh: refresh,
                        onNotification: onNotification,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        generateImage: generateImage,
                        searchGiphy: searchGiphy,
                        //selectVideos: selectVideos,
                        circleObjects: circleObjects,
                        globalEventBloc: globalEventBloc,
                        captureMedia: captureMedia,
                        selectMedia: selectMedia,
                        circleObjectBloc: circleObjectBloc,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.media,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.collections,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ), //image
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Notes,
                        send: send,
                        circleListBloc: circleListBloc,
                        userCircleCache: userCircleCache,
                        circleRecipeBloc: circleRecipeBloc,
                        userCircleBloc: userCircleBloc,
                        circleFileBloc: circleFileBloc,
                        export: export,
                        userFurnace: userFurnace,
                        deleteObject: deleteObject,
                        downloadFile: downloadFile,
                        pickFiles: pickFiles,
                        refresh: refresh,
                        onNotification: onNotification,
                        circleObjects:
                            circleObjects, //_filterObjects(circleObjects, "Notes"),
                        circleObjectBloc: circleObjectBloc,
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notes,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.collections_bookmark,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ),
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CalendarHolder(
                        userFurnace: userFurnace,
                        circleObjects: circleObjects,
                        globalEventBloc: globalEventBloc,
                        circleFileBloc: circleFileBloc,
                        userCircleCache: userCircleCache,
                        circleObjectBloc: circleObjectBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.events,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.event,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ),
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Links,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleListBloc: circleListBloc,
                        circleFileBloc: circleFileBloc,
                        pickFiles: pickFiles,
                        export: export,
                        circleObjects:
                            circleObjects, //_filterObjects(circleObjects, "Links"),
                        globalEventBloc: globalEventBloc,
                        refresh: refresh,
                        onNotification: onNotification,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        downloadFile: downloadFile,
                        unpinObject: unpinObject,
                        sendLink: sendLink,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.links,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.open_in_browser,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ),
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Lists,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleListBloc: circleListBloc,
                        circleFileBloc: circleFileBloc,
                        pickFiles: pickFiles,
                        export: export,
                        refresh: refresh,
                        onNotification: onNotification,
                        circleObjects:
                            circleObjects, //_filterObjects(circleObjects, "Lists"),
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        downloadFile: downloadFile,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.lists,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.checklist,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ), //check_box
                  ]),
            )),
        InkWell(
            //() => _seeRecipes(Navigator.of(context), context),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Recipes,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleFileBloc: circleFileBloc,
                        circleListBloc: circleListBloc,
                        pickFiles: pickFiles,
                        downloadFile: downloadFile,
                        export: export,
                        refresh: refresh,
                        onNotification: onNotification,
                        circleObjects:
                            circleObjects, //_filterObjects(circleObjects, "Recipes"),
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.recipes,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.restaurant,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    ),
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Credentials,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleListBloc: circleListBloc,
                        circleFileBloc: circleFileBloc,
                        circleObjects: circleObjects,
                        downloadFile: downloadFile,
                        refresh: refresh,
                        onNotification: onNotification,
                        export: export,
                        pickFiles: pickFiles,
                        //_filterObjects(circleObjects, "Credentials"),
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.credentials,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.login,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    )
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.Files,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleListBloc: circleListBloc,
                        circleFileBloc: circleFileBloc,
                        circleObjects: circleObjects,
                        downloadFile: downloadFile,
                        pickFiles: pickFiles,
                        refresh: refresh,
                        onNotification: onNotification,
                        export: export,
                        //_filterObjects(circleObjects, "Credentials"),
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.files,
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.attach_file,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    )
                  ]),
            )),
        InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => VaultObjectDisplay(
                        displayType: DisplayType.AgoraCalls,
                        send: send,
                        userCircleCache: userCircleCache,
                        userFurnace: userFurnace,
                        circleListBloc: circleListBloc,
                        circleFileBloc: circleFileBloc,
                        circleObjects: circleObjects,
                        downloadFile: downloadFile,
                        pickFiles: pickFiles,
                        refresh: refresh,
                        onNotification: onNotification,
                        export: export,
                        globalEventBloc: globalEventBloc,
                        videoControllerBloc: videoControllerBloc,
                        videoControllerDesktopBloc: videoControllerDesktopBloc,
                        circleObjectBloc: circleObjectBloc,
                        deleteObject: deleteObject,
                        userCircleBloc: userCircleBloc,
                        circleRecipeBloc: circleRecipeBloc,
                        circleVideoBloc: circleVideoBloc,
                        circleImageBloc: circleImageBloc,
                        circleAlbumBloc: circleAlbumBloc,
                        unpinObject: unpinObject,
                        shuffle: false,
                        key: key,
                      )));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: globalState.theme.memberObjectBackground,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Agora Calls",
                      textScaler: const TextScaler.linear(1.25),
                      style: TextStyle(
                          color: globalState.theme.buttonIcon,
                          fontWeight: FontWeight.bold),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                    Icon(
                      Icons.videocam,
                      size: 37,
                      color: globalState.theme.bottomIcon,
                    )
                  ]),
            )),
      ],
    );
  }
}
