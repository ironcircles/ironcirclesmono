import 'package:flutter/material.dart';
import 'package:ironcirclesapp/services/cache/database_provider.dart';
import 'package:rxdart/rxdart.dart';


class DatabaseBloc {
  final _createdDatabase = PublishSubject<bool>();

  Stream<bool> get databaseCreated => _createdDatabase.stream;

  createDatabase() async {
    try {
      //User user = await _authService.validateCredentials(username, password);

      await DatabaseProvider.db.database;
      // debugPrint(user);
      _createdDatabase.sink.add(true);
    } catch (error) {
      debugPrint('$error');
      _createdDatabase.sink.addError(error);
    }
  }

  static clearCache() async {
    await DatabaseProvider.db.clearDatabase();
  }

  dispose() async {
    await _createdDatabase.drain();
    _createdDatabase.close();
  }
}
