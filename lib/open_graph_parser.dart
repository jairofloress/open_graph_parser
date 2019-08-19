import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'dart:async';
import 'dart:convert';

class OpenGraphParser {
  /// Defines a map with all open-graph tags from a given website
  ///
  /// @param url The URL where the OG-data should be extracted from
  /// @returns A map containing the OG-data.
  static Future<Map<String, dynamic>> getOpenGraphData(String url) async {
    var response = await http.get(url);

    return getOpenGraphDataFromResponse(response);
  }

  static Map<String, dynamic> getOpenGraphDataFromResponse(http.Response response) {
    var requiredAttributes = ['title', 'image'];
    Map<String, dynamic> data = new Map<String, dynamic>();

    if (response.statusCode == 200) {
      var document = parser.parse(utf8.decode(response.bodyBytes));
      var openGraphMetaTags = _getOpenGraphData(document);

      if(openGraphMetaTags.isNotEmpty)
      openGraphMetaTags.forEach((element) {
        var ogTagTitle = element.attributes['property'].split("og:")[1];
        var ogTagValue = element.attributes['content'];

        if ((ogTagValue != null && ogTagValue != "") ||
            requiredAttributes.contains(ogTagTitle)) {
          if (ogTagValue == null || ogTagValue.length == 0) {
            ogTagValue = _scrapeAlternateToEmptyValue(ogTagTitle, document);
          }
          data[ogTagTitle] = ogTagValue;
        }
      });
      else {
        data['title'] = document.head.parent.querySelector("title").nodes[0].text;
        var images = document.querySelectorAll("img");
        if(images.isNotEmpty){
          for (var image in images) {
            var image_path = image.attributes["src"];
            if (isValidUrl(image_path)){
              data["image"]= image.attributes["src"];
              break;
            }else{
              if(isValidWebPath(image_path)){
                data["image"]= response.request.url.origin + image_path;
                break;
              }
            }
          }
          return data;
        }
      }
    }

    return data;
  }

  static bool isValidWebPath(link) {
    final regex = RegExp(r"^\/([^?\/]+)");
      if (regex.hasMatch(link)) {
        return true;
    }
    return false;
  }

  static bool isValidUrl(link) {
    String regexSource =
        "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]";
    final regex = RegExp(regexSource);
    final matches = regex.allMatches(link);
    for (Match match in matches) {
      if (match.start == 0 && match.end == link.length) {
        return true;
      }
    }
    return false;
  }

  static String _scrapeAlternateToEmptyValue(
    String tagTitle, Document document) {
    if (tagTitle == "title") {
      return document.head.getElementsByTagName("title")[0].text;
    }

    if (tagTitle == "image") {
      var images = document.body.getElementsByTagName("img");

      if (images.length > 0) {
        return images[0].attributes["src"];
      }

      return "";
    }

    return "";
  }

  static List<Element> _getOpenGraphData(Document document) {
    return document.head.querySelectorAll("[property*='og:']");
  }
}
