import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasPermissions = false;
  String NAME = "SafariBora";
  double? heading = 0;
  double? previous_heading = 0;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    _fetchPermissionStatus();
    FlutterCompass.events!.listen((event) {
      setState(() {
        heading = event.heading! < 0 ? 360 + event.heading! : event.heading;
      });

      if ((previous_heading! - heading!).abs() > 1) {
        previous_heading = heading!;
        dbRef
            .child("Boats")
            .child(NAME)
            .update({'Orientation': heading!.ceil()});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Magnetometer'),
          centerTitle: true,
          backgroundColor: Colors.grey.shade900,
        ),
        body: Builder(builder: (context) {
          if (_hasPermissions) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${heading!.ceil()}°",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Stack(alignment: Alignment.center, children: [
                        Image.asset("assets/cadrant.png"),
                        Transform.rotate(
                          angle: ((heading ?? 0) * (math.pi / 180) * -1),
                          child: Image.asset(
                            "assets/compass.png",
                            scale: 1.1,
                          ),
                        )
                      ])),
                ],
              ),
            );
          } else {
            return _buildPermissionSheet();
          }
        }),
      ),
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Location Permission Required'),
          ElevatedButton(
            child: const Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          )
        ],
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }
}
