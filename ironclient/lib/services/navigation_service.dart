import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/landing.dart';
import 'package:ironcirclesapp/services/cache/table_userfurnace.dart';

final NavigationService navService = NavigationService();

class NavigationService<T, U> {
  static GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  Future<T?> pushNamed(String routeName, {Object? args}) async =>
      navigationKey.currentState!.pushNamed<T>(
        routeName,
        arguments: args,
      );

  Future<T?> push(Route<T> route) async =>
      navigationKey.currentState!.push<T>(route);

  Future<T?> pushReplacementNamed(String routeName, {Object? args}) async =>
      navigationKey.currentState!.pushReplacementNamed<T, U>(
        routeName,
        arguments: args,
      );

  Future<T?> pushNamedAndRemoveUntil(
    String routeName, {
    Object? args,
    bool keepPreviousPages = false,
  }) async =>
      navigationKey.currentState!.pushNamedAndRemoveUntil<T>(
        routeName,
        (Route<dynamic> route) => keepPreviousPages,
        arguments: args,
      );

  Future<T?> pushAndRemoveUntil(
    Route<T> route, {
    bool keepPreviousPages = false,
  }) async =>
      navigationKey.currentState!.pushAndRemoveUntil<T>(
        route,
        (Route<dynamic> route) => false,
      );

  logout(UserFurnace userFurnace,
      {String toastMessage = 'security token expired'}) async {
    //if (toastMessage.isEmpty) toastMessage = AppLocalizations.of(context).securityTokenExpired;

    LogBloc.insertLog('device logged out. will throw more than once',
        'NavigationService.logout');

    ///make sure this is the network in GlobalState
    if (globalState.userFurnace == null ||
        userFurnace.userid == globalState.userFurnace!.userid ||
        globalState.loggingOut == true) {
      if (globalState.loggedOutToLanding == false) {
        ///prevents the UI from being logged out more than once in case push token fails in multiple spots
        globalState.loggedOutToLanding = true;

        userFurnace.connected = false;
        userFurnace.token = null;
        await TableUserFurnace.upsert(userFurnace);

        return await pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Landing(toast: toastMessage)),
          keepPreviousPages: false,
        );
      }
    } else {
      userFurnace.connected = false;
      userFurnace.token = null;
      await TableUserFurnace.upsert(userFurnace);

      // return await pushAndRemoveUntil(
      //   MaterialPageRoute(
      //       builder: (context) => const Home(tab: 3)),
      //   keepPreviousPages: false,
      // );

      globalState.globalEventBloc.broadcastPopToHomeOpenTab(3);
    }
  }

  Future<bool> maybePop([Object? args]) async =>
      navigationKey.currentState!.maybePop<bool>(args as bool?);

  bool canPop() => navigationKey.currentState!.canPop();

  void goBack({T? result}) => navigationKey.currentState!.pop<T>(result);
}
