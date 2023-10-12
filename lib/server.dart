import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/model/pixel.dart';

import 'package:server/constant.dart';

Future<void> start() async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4040);
  print('Listening on localhost:${server.port}');
  List<WebSocket> sockets = [];
  final mongoDB = await Db.create('mongodb+srv://$USERNAME:$PASSWORD@pixelwar.y0ni9ap.mongodb.net/pixelWar?authSource=admin&retryWrites=true&w=majority');
  await mongoDB.open();
  final collection = mongoDB.collection('pixels');
  await for (HttpRequest request in server) {
    if (request.uri.path == '/ws') {
      var socket = await WebSocketTransformer.upgrade(request);
      print('Client connected!');
      sockets.add(socket);
      socket.listen((message) {
        print('Received message: $message');
        try {
          final json = jsonDecode(message);
          if (json.containsKey("x") && json.containsKey("y") && json.containsKey("color") && json["x"] is int && json["y"] is int && json["color"] is int) {
            print("Pixel received");
            collection.insertOne(json);
            broadcast(message, sockets);
            return;
          }
        } catch (e) {
          print(e);
          return;
        }
      });
    } else if (request.method == 'GET') {
      handleGetRequest(request,collection);
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}


void handleGetRequest(HttpRequest req,DbCollection collection) async {
  HttpResponse res = req.response;
  res.headers.contentType = ContentType.json;
  final allData = await  collection.find().fold([], (previous, element) => [...previous, jsonEncode(Pixel.fromJson(element))]);
  res.write("[${allData.join(",")}]");
  res.close();
}

void broadcast(String message, List<WebSocket> sockets) {
  for (var socket in sockets) {
    socket.add(message);
  }
}

void broadcastWithout(String message, List<WebSocket> sockets, WebSocket without) {
  for (var socket in sockets) {
    if (socket != without) {
      socket.add(message);
    }
  }
}
