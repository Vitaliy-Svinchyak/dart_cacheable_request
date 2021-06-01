class SerializableRequest {
  int id;
  String actionName;
  String body;
  String metadata;
  int maxRetries;
  DateTime createdAt;

  SerializableRequest();

  SerializableRequest.fromJson(Map<String, dynamic> json)
      : this.id = json['id'] as int,
        this.actionName = json['actionName'] as String,
        this.body = json['body'] as String,
        this.metadata = json['metadata'] as String,
        this.maxRetries = json['maxRetries'] as int,
        this.createdAt = DateTime.parse(json['createdAt'] as String);

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'actionName': this.actionName,
        'body': this.body,
        'metadata': this.metadata,
        'maxRetries': this.maxRetries,
        'createdAt': this.createdAt,
      };
}
