import 'package:http/http.dart' as http;

class AuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _client;

  AuthClient(this.headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(headers));
  }

  @override
  void close() {
    _client.close();
  }
}
