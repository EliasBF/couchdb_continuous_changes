import 'dart:convert';
import 'package:couchdb_continuous_changes/couchdb_continuous_changes.dart';

Future<void> main() async {
  CouchDbFeed couchDbFeed = CouchDbFeed(
    scheme: "http",
    host: "localhost",
    port: 5984,
    username: "username",
    password: "password",
    database: "database"
  );

  final continuousFeed = await couchDbFeed.continuous();
  continuousFeed.listen((FeedResponse item) {
    print("feed sequence: ${item.seq}");
    print("feed doc id: ${item.id}");
    print("feed doc data: ${json.encode(item.doc)}");
  });
}