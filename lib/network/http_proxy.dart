import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:pica_comic/foundation/log.dart';
import '../foundation/app.dart';

class HttpProxyRequest {
  String host;
  int port;

  var sni = <String>[];

  final void Function() stop;

  HttpProxyRequest(this.host, this.port, this.stop);
}

class _HttpProxyHandler {
  var content = "";
  late Socket client;
  Socket? serverSocket;

  void handle(
      Socket c, void Function(HttpProxyRequest request) onRequest) async {
    try {
      client = c;
      await for (var d in client) {
        if (serverSocket == null) {
          content += const Utf8Decoder().convert(d);
          if (content.contains("\n")) {
            if (content.split(" ").first != "CONNECT") {
              client
                  .write("HTTP/1.1 400 Bad Request\nContent-Type: text/plain\n"
                  "Content-Length: 29\n\nBad Request: Invalid Request");
              client.flush();
              client.close();
              return;
            }
            var uri = content
                .split('\n')
                .first
                .split(" ")
                .firstWhere((element) => element.contains(":"));
            bool stop = false;
            var request = HttpProxyRequest(
                uri.split(":").first, int.parse(uri.split(":").last), () {
              stop = true;
            });
            onRequest(request);
            if (stop) {
              client.close();
              return;
            }
            forward(request.host, request.port);
          }
        }
        if (serverSocket != null) {
          serverSocket!.add(d);
        }
      }
      close();
    } catch (e) {
      close();
    }
  }

  void close() {
    try {
      client.close();
      serverSocket?.close();
    } catch (e) {
      //
    }
  }

  void forward(String host, int port) async {
    try {
      serverSocket = await Socket.connect(host, port);
      serverSocket?.listen((event) {
        client.add(event);
      }, onDone: () {
        client.close();
        serverSocket = null;
      }, onError: (e) {
        client.close();
        serverSocket = null;
      }, cancelOnError: true);
      client.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      client.flush();
    } catch (e) {
      close();
    }
  }
}

typedef RequestHandler = void Function(HttpProxyRequest request);

class HttpProxyServer {
  HttpProxyServer(this.handler, this.port);

  final RequestHandler handler;

  final int port;

  ServerSocket? socket;

  void run() {
    runZonedGuarded(() async{
      socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      socket?.listen((event) => _HttpProxyHandler().handle(event, handler));
    }, (error, stack) async{
      LogManager.addLog(LogLevel.error, "Network", "Proxy Server\n$error\n$stack");
      try {
        await socket?.close();
        socket = null;
      }
      finally{
        run();
      }
    });
  }

  void close(){
    socket?.close();
  }

  static HttpProxyServer? _server;

  static void startServer(){
    try {
      final file = File("${App.dataPath}/rule.json");
      var json = const JsonDecoder().convert(file.readAsStringSync());
      if (_server == null) {
        _server = HttpProxyServer((request) {
          final file = File("${App.dataPath}/rule.json");
          final json = const JsonDecoder().convert(file.readAsStringSync());
          if (json["rule"][request.host] != null) {
            request.host = json["rule"][request.host];
          }
        }, json["port"]);
        _server?.run();
      }
    }
    catch(e){
      //
    }
  }

  static reload(){
    _server?.close();
    _server = null;
    startServer();
  }

  static void createConfigFile(){
    var file = File("${App.dataPath}/rule.json");
    if(!file.existsSync()){
      var rule = {
        "port": 7891,
        "rule": {
          "picaapi.picacomic.com": "104.21.91.145",
          "img.picacomic.com": "104.21.91.145",
          "storage1.picacomic.com": "104.21.91.145",
          "storage-b.picacomic.com": "104.21.91.145",
          "e-hentai.org": "172.67.0.127",
          "exhentai.org": "178.175.129.254",
          "s.exhentai.org": "178.175.129.254"
        },
        "sni": [
          "e-hentai.org",
          "exhentai.org",
          "s.exhentai.org"
        ]
      };
      var spaces = ' ' * 4;
      var encoder = JsonEncoder.withIndent(spaces);
      file.writeAsStringSync(encoder.convert(rule));
    }
  }
}