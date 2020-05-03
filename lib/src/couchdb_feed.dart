import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:couchdb_continuous_changes/src/feed_response.dart';

class CouchDbFeed {
  String userInfo;
  Uri couchDbUri;

  CouchDbFeed({
    String host = "0.0.0.0",
    String scheme = "http",
    String username,
    String password,
    int port = 5984,
    String database
  }) {
    if ((database ?? "").isEmpty) {
      throw new Exception("database is required");
    }
    this.userInfo = username != null && password != null
      ? "$username:$password"
      : null;
    final regExp = RegExp(r"http[s]?://");
    if (host.startsWith(regExp)) {
      host = host.replaceFirst(regExp, "");
    }
    couchDbUri = Uri(
        scheme: scheme, host: host, port: port, userInfo: userInfo, path: database);
  }

  String getAuthCredentials() {
    return userInfo != null
      ? const Base64Encoder().convert(couchDbUri.userInfo.codeUnits)
      : null;
  }

  Map<String, String> getDefaultHeaders() {
    Map<String, String> headers = <String, String>{
      "Accept": "application/json",
      "Content-Type": "application/json"
    };
    String authCredentials = getAuthCredentials();
    if (authCredentials != null) {
      headers["Authorization"] = "Basic $authCredentials";
    }
    return headers;
  }

  Stream<List<FeedResponse>> parseFeed(Stream<String> stream) {
    return stream.map((feed) => feed.trim().isEmpty
      ? List.from([])
      : feed.split("\n")
          .where((item) => item.trim().isNotEmpty)
          .map((item) => json.decode(item))
          .where((json) => (json as Map<String, dynamic>).containsKey("last_seq") == false)
          .map((json) => FeedResponse.fromJson((json as Map<String, dynamic>)))
          .toList());
  }

  Future<Stream<String>> changesStream({
    String lastEventId = null
  }) async {
    final Client client = Client();
    final String query = "feed=continuous&include_docs=true" + (
      lastEventId != null ? "&last-event-id=$lastEventId" : ""
    );
    final String path = "${couchDbUri.path}/_changes?$query" ;
    final request = Request("GET", couchDbUri.resolve(path));
    request.headers.addAll(getDefaultHeaders());
    final response = await client.send(request);
    final stream = response.stream.asBroadcastStream().transform(utf8.decoder);
    if (response.statusCode != 200) {
      throw Exception(await stream.first);
    }
    return stream;
  }

  Stream<FeedResponse> continuous({
    String lastEventId = null
  }) async* {
    while (true) {
      final changesStream = await this.changesStream(lastEventId: lastEventId);
      await for (List<FeedResponse> feeds in parseFeed(changesStream)) {
        if (feeds.isEmpty) continue;
        for (FeedResponse feed in feeds) yield feed;
        lastEventId = feeds.last.seq;
      }
    }
  }
}
