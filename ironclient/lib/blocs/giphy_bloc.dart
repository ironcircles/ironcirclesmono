import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';
import 'package:rxdart/rxdart.dart';
//import 'package:ironcirclesapp/services/giphy_service.dart';

class GiphyBloc {
  //final _giphyService = GiphyService();
  final _tenorService = TenorService();

  final _giphyResult = PublishSubject<List<GiphyOption>>();
  Stream<List<GiphyOption>> get giphyResults => _giphyResult.stream;

  final _categoryResult = PublishSubject<List<TenorCategory>>();
  Stream<List<TenorCategory>> get categoryResult => _categoryResult.stream;

  final _autoCompleteResult = PublishSubject<List<String>>();
  Stream<List<String>> get autoCompleteResult => _autoCompleteResult.stream;

  search(String phrase, int queryNumber) async {
    try {
      //var retValue = await _giphyService.searchGiphy(phrase);

      var retValue = await _tenorService.search(phrase, queryNumber);

      if (retValue.isNotEmpty)
        _giphyResult.sink.add(retValue);
      else
        throw ("gif not found");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _giphyResult.sink.addError(error);
    }
  }

  scrollForMore(String phrase, int queryNumber) async {
    try {
      var retValue = await _tenorService.search(phrase, queryNumber);
      _giphyResult.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _giphyResult.sink.addError(error);
    }
  }

  autoComplete(String phrase) async {
    try {
      //var retValue = await _giphyService.searchGiphy(phrase);

      var retValue = await _tenorService.autoComplete(phrase);

      if (retValue.isNotEmpty) _autoCompleteResult.sink.add(retValue);
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _giphyResult.sink.addError(error);
    }
  }

  trending() async {
    try {
      //var retValue = await _giphyService.searchGiphy(phrase);

      var retValue = await _tenorService.trending();

      if (retValue.isNotEmpty)
        _giphyResult.sink.add(retValue);
      else
        throw ("gif not found");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _giphyResult.sink.addError(error);
    }
  }

  category(int category) async {
    try {
      //var retValue = await _giphyService.searchGiphy(phrase);

      var retValue = await _tenorService.category(category);

      if (retValue.isNotEmpty)
        _categoryResult.sink.add(retValue);
      else
        throw ("gif not found");
    } catch (error, trace) {
      LogBloc.insertError(error, trace);
      debugPrint('$error');
      _giphyResult.sink.addError(error);
    }
  }

  dispose() async {
    await _giphyResult.drain();
    _giphyResult.close();

    await _categoryResult.drain();
    _categoryResult.close();

    await _autoCompleteResult.drain();
    _autoCompleteResult.close();
  }
}
