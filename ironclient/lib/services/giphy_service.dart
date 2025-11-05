

/*
class GiphyOption {
  String url = '';
  String preview = '';
  int? height;
  int? width;

  GiphyOption({required this.url, required this.preview, this.height, this.width });
}



class GiphyService {
  Client client = Client();

  Future<List<GiphyOption>> searchGiphy(String phrase) async {

    try {
      List<GiphyOption> retValue = [];

      phrase = phrase.replaceAll("GIPHY ", "").trim();

      if (phrase.isEmpty) {
        throw Exception('No phrase entered');
      }

      String url = Urls.GIPHY_TRANSLATE;
      url = url + "?api_key=" + Urls.GIPHYKEY;
      url = url + "&q=" + phrase.replaceAll(" ", "+");
      url = url + "&limit=75";
      // url = url + "&weirdness=10";

      //debugPrint("Giphy URL = " + url);

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //debugPrint(response.body);

        var jsonResponse = json.decode(response.body);


        //fixed_width_downsampled
        //fixed_width_small
        //downsized_medium

        for (var url in jsonResponse["data"]) {
          if (url["images"]["fixed_width"]["url"] == null ||
              url["images"]["fixed_width_downsampled"]["url"] == null) continue;


          int width = int.parse(url["images"]["fixed_width"]["width"]);
          int height = int.parse(url["images"]["fixed_width"]["height"]);

          if (width > InsideConstants.MESSAGEBOXSIZE) {
            double ratio = width / InsideConstants.MESSAGEBOXSIZE;
            width = InsideConstants.MESSAGEBOXSIZE.toInt();

            height = (height ~/ ratio);
          }


          retValue.add(GiphyOption(
              url: url["images"]["fixed_width"]["url"],
              height: height,
              width: width,
              preview: url["images"]["fixed_width_downsampled"]["url"]));
        }

        //return retValue;

        // If the call to the server was successful, parse the JSON
        //return User.fromJson(json.decode(response.body));
      } else {
        debugPrint(response.statusCode.toString());
        // If that call was not successful, throw an error.
        throw Exception('Giphy search failed');
      }

      return retValue;
    } catch(err){

      debugPrint('GiphyService.searchGiphy: $err');
      throw(err);
    }

    /*
  JSONObject jsonResponse = (JSONObject) response;

                                jsonResponse = jsonResponse.getJSONObject("data");
                                jsonResponse = jsonResponse.getJSONObject("images");
                                jsonResponse = jsonResponse.getJSONObject("downsized");
                                String url = jsonResponse.getString("url");
   */
  }


}

 */
