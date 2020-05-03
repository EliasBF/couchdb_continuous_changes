class FeedResponse {
  final String seq;
  final String id;
  final dynamic doc;

  FeedResponse({
    this.seq,
    this.id,
    this.doc
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      seq: json["seq"],
      id: json["id"],
      doc: json["doc"]
    );
  }
}