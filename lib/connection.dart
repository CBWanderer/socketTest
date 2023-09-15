import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:v4/models/index.dart';
// import 'dart:async';
// import 'dart:convert';

class SocketConnection {
  static final SocketConnection _instance = SocketConnection._internal();

  factory SocketConnection() {
    return _instance;
  }

  SocketConnection._internal();

  bool connected = false;
  io.Socket? socket;

  Map<String, List<Function(Map<String, dynamic> data)>> hooks = {};

  final Logger _log = Logger(printer: SimplePrinter());

  int idx = 0;

  // late User user;

  addHook(String hook, Function(Map<String, dynamic> data) callback) {
    if (hooks[hook] == null) {
      hooks[hook] = [];
    }
    hooks[hook]!.add(callback);
  }

  Uint8List int32bytes(int value) =>
      Uint8List(4)..buffer.asInt32List()[0] = value;

  send(String action, Map<String, dynamic> data) {
    idx++;
    var payload = data;
    payload['id'] = idx;
    payload['time'] = DateTime.now().toString();
    payload['driverId'] = 1;
    payload['version'] = 1;
    payload['action'] = action;

    _log.log(Level.debug, payload);

    socket!.emit('mobile-driver-app', payload);
  }

  sendSync() {
    send('sync', {
      'schedules': [],
      'techreview': {},
      'driverSignature': '',
      'notifications': {},
      'avatar': '',
      'calendar': {'lastupdate': null},
    });
  }

  disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }

  connect(String token) {
    // Dart client

    // IO.Socket
    socket ??= io.io(
      "https://www.ecorouteonline.com:8443",
      io.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .disableAutoConnect() // disable auto-connection
          .setQuery({
            "HttpHeaders.contentTypeHeader": "application/json",
            'token': token,
            'app': 'mobile-driver-app',
            'deviceId': '1'
          }) // optional
          .build(),
    );

    if (!socket!.connected) {
      // _log.log(Level.debug, "Connecting...");
      print("--> Connecting...");

      // this.user = user;

      socket!.onConnect((_) {
        // _log.log(Level.info, "Connected");
        print("--> Connected");
        sendSync();

        connected = true;
      });

      socket!.onConnectError((data) {
        _log.log(Level.error, "Connecting error: $data");
        // print(object)
      });

      socket!.onError((data) {
        _log.log(Level.error, "Error: $data");
      });

      socket!.onAny((event, data) {
        print("event------------------------------");
        print(data);
      });

      socket!.on(
        'server-ws',
        (data) {
          Logger().log(Level.debug, data);
          for (var hook in hooks.keys) {
            if (data["action"] == hook) {
              var funcs = hooks[hook] ?? [];
              for (var func in funcs) {
                func(data);
              }
            }
          }
        },
      );

      socket!.onDisconnect((_) => Logger().log(Level.debug, 'disconnect'));
      socket!.on('fromServer', (_) => Logger().log(Level.debug, _));

      // socket!.connect();
    } else {
      // _log.log(Level.debug, "Already connected");
      print("--> Already Connected!");
    }
  }
}


// class ServerConnection {
//   String url;
//   String token;
//   // SocketIOManager manager;
//   // SocketIO ws;
//   StreamController messagesController = StreamController.broadcast();
//   bool connected;
//   StreamController<bool> conectionStatus;
//   StreamSubscription streamSubs;
//   StreamSubscription poolSub;
//   bool autoReconnect = true;
//   bool sending;
//   Pool messagePool = new Pool();

//   static final ServerConnection _singleton = ServerConnection._internal();

//   factory ServerConnection() {
//     return _singleton;
//   }

//   ServerConnection._internal() {
//     url = new Config().wsUrl;
//     connected = false;
//     conectionStatus = new StreamController.broadcast(onListen: () {
//       conectionStatus.sink.add(connected);
//     });
//     // manager = new SocketIOManager();
//   }

//   Future<void> disconnect() async {
//     await streamSubs?.cancel();
//     await poolSub?.cancel();
//     // poolSub = null;
//     // streamSubs = null;
//     // await manager.clearInstance(ws);
//     // ws = null;
//   }

//   Future<void> connect() async {
//     if (!connected) {
//       // queue = [];
//       sending = false;
//       // try {
//       //   // if (ws != null) {
//       //   //   await manager.clearInstance(ws);
//       //   //   ws = null;
//       //   }

//       // if (ws == null) {
//       //   String udid = await FlutterUdid.udid;
//       //   ws = await manager.createInstance(SocketOptions(Config().wsioUrl,
//       //       query: {
//       //         'token': token,
//       //         'app': 'mobile-driver-app',
//       //         'deviceId': udid
//       //       }));
//       poolSub ??= messagePool.queueSize.stream.listen((status) async {
//         // Logger().log(Level.debug, '3333333333 Escuchando dataChaged: $status');
//         // Logger().log(Level.debug, "Status Change... Now is $status");
//         // Logger().log(Level.debug, "Sending flag: $sending");
//         if (status != 0 && connected && !sending) {
//           // Logger().log(Level.debug, "Starting transmition");
//           // sending = true;
//           sendPoolData();
//         }
//       });

//       // ws.onConnect.listen((l) {
//       //   connected = true;

//       //   conectionStatus.sink.add(connected);
//       //   Logger().log(Level.debug, "Connected");

//       //   if (!sending) {
//       //     // sending = true;
//       //     sendPoolData();
//       //   }
//       // });

//       // ws.onConnecting.listen((d) {
//       //   Logger().log(Level.debug, "Conectando");
//       // });

//       // ws.onConnectError.listen((d) {
//       //   Logger().log(Level.debug, "Error Conectando: $d");
//       // });

//       // ws.onDisconnect.listen((reason) async {
//       //   connected = false;
//       //   sending = false;
//       //   conectionStatus.sink.add(connected);
//       //   Logger().log(Level.debug, "Disconnected: $reason");
//       // });

//       // ws.on("server-ws").listen((message) {
//       //   var messageMap = {};
//       //   var messageList = [];
//       //   try {
//       //     Logger().log(Level.debug, "Received");
//       //     Logger().log(Level.debug, message.toString());

//       //     if (message is List) {
//       //       messageList = message;
//       //     } else
//       //       messageList.add(message);

//       //     for (messageMap in messageList) {
//       //       if (messageMap.containsKey("received")) {
//       //         Logger().log(Level.debug, 'Deleting message ${messageMap['received']}');
//       //         messagePool.deleteFromPool(messageMap['received']);
//       //       } else {
//       //         messagesController.add(message);
//       //       }
//       //     }
//       //   } catch (e) {
//       //     Logger().log(Level.debug, e.toString());
//       //     messageMap = {"message": message};
//       //   }
//       // });
//       // var user = UserRepository().currentUser;
//       // ws.on("workload-driver", (message) {
//       //   Logger().log(Level.debug, '**** Message for driver ${user.driverId} ****');
//       //   processWorkload(message);
//       // });

//       // addToPool({
//       //   'action': 'subscribe',
//       //   'driverId': user.driverId,
//       // });
//       //   }
//       //   ws.connect();
//       // } catch (e) {
//       //   Logger().log(Level.debug, e);
//       // }
//     }
//   }

//   void processWorkload(Map<String, dynamic> workload) {
//     String wlMode = workload['loadMode'];

//     workload.remove('loadMode');

//     //We'll process only fullmode for now
//     Logger().log(Level.debug, " Processing!!! Mode: $wlMode");

//     //En la app solo debería llegar uno siempre
//     Logger().log(Level.debug, 'Elementos a procesar: ${workload.length}');

//     if (workload.length > 0) {
//       //De momento solo procesaremos un workload. Solo debería llegar uno a la app movil.
//       Map wl = workload[workload.keys.first];

//       //Datos del chofer. de momento solo es necesario el calendario
//       if (wl.keys.contains('driverInfo')) {
//         if (wl['driverInfo'] is Map && wl['driverInfo']['calendar'] != null) {
//           Logger().log(Level.debug, ' Recibiendo nuevo calendario... ***');
//           CalendarBloc().add(
//               ReceiveCalendarEvent({'calendar': wl['driverInfo']['calendar']}));
//         }

//         if (wl.keys.contains('dates')) {
//           var dates = (wl['dates'] as Map).keys;
//           Logger().log(Level.debug, 'Fechas en el Workload: ${dates.length}');

//           for (String dateKey in dates) {
//             Logger().log(Level.debug, 'Procesando $dateKey');
//             var currentDate = wl['dates'][dateKey];
//             var riders = (currentDate['riders']) as Map;
//             var trips = (currentDate['trips']) as Map;

//             // Leer trips
//             Map<String, dynamic> tripsKeys = {};
//             if (riders != null && riders.length > 0) {
//               riders.forEach((key, value) {
//                 var inTrips = value['trips'] as List;
//                 inTrips.forEach((element) {
//                   tripsKeys[element] = key;
//                 });
//               });
//             }

//             var tripList = <RoutePoint>[];
//             trips.forEach((key, trip) {
//               if (trip['pickup'] != null) tripList.add(RoutePoint());
//             });

//             // tripList.add(RoutePoint(address: ));

//             // if (currentDate[]){}
//           }
//         }

//         // List trips = wl['riders']

//         // Logger().log(Level.debug, 
//         //     "Tenemos información de chofer -------------------------------- ");
//       }
//     }
//   }

//   void addToPool(Map<String, dynamic> data,
//       {int priority, DateTime time, bool sent}) async {
//     // Logger().log(Level.debug, "1111111111 Adding to pool from Connection: \n$data");
//     messagePool.addToPool(json.encode(data),
//         priority: priority, time: time, sent: sent);
//   }

//   void sendPoolData() async {
//     //In developer mode dont send data
//     // bool developer = SettingsBloc().getSetting('developer') == 'true';

//     // Logger().log(Level.debug, '********* Start sending pool data *********');

//     // Logger().log(Level.debug, 'Value of sending flag: $sending');

//     // Logger().log(Level.debug, 'Value of connected flag: $connected');

//     if (connected && !sending) {
//       sending = true;
//       while (sending) {
//         List d = await messagePool.getPool(limit: 10);

//         // Logger().log(Level.debug, 'Read elements: ${d.length}');

//         if (d.length > 0) {
//           List<int> ids = [];
//           for (var i = 0; i < d.length; i++) {
//             // Logger().log(Level.debug, 'Cycle start for $i');
//             Map<String, dynamic> data = json.decode(d[i]["data"]);

//             data["id"] = d[i]['id'];
//             data["time"] =
//                 DateTime.fromMillisecondsSinceEpoch(d[i]['time']).toString();

//             if (developer) {
//               Logger().log(Level.debug, '[OFFLINE MODE]');
//               Logger().log(Level.debug, d[0]);
//               await messagePool.deleteFromPool(d[i]['id']);
//             } else {
//               Logger().log(Level.debug, "Sending ${data['id']}");
//               Logger().log(Level.debug, data);
//               String channel = data['channel'] ?? "mobile-driver-app";
//               data.remove('channel');
//               // ws.emit(channel, [data]);
//               await messagePool.updateSent(id: data['id']);
//             }
//             // Logger().log(Level.debug, 'Cycle end for $i');
//           }
//         } else {
//           // Logger().log(Level.debug, 'Finished sendind pool');
//           sending = false;
//           // await messagePool.resetNotSent();
//         }
//       }
//     }
//     // Logger().log(Level.debug, '********* Finish send pool data');
//   }

//   void close() {}

//   void dispose() {
//     conectionStatus.close();
//   }
// }
