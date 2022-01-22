import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

const String GOOGLE_MAPS_KEY = "AIzaSyDpSH_gylG1i9lfwE18UUULHMjTyUjeddk";

class Client {
  final String url = "";

  Future<Map> get(String request, [Map queryParams = const {}]) async {
    return json.decode((await http.get(Uri.parse(request))).body);
  }

  Future<Map> post(String path, Map body) async {
    return {};
  }
}

class FirebaseListener {
  FirebaseListener() : super() {
    _startListening();
  }

  final controller = StreamController<Map>.broadcast();

  Stream<Map> get stream => controller.stream;

  void dispose() {
    controller.close();
  }

  Future<void> _startListening() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      Map data = json.decode(event.notification!.body!.toString());
      controller.sink.add(data);
    });
  }
}

FirebaseListener firebaseListener = FirebaseListener();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: FutureBuilder(
          future: Firebase.initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const PickLobbyScreen();
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}

class PickLobbyScreen extends StatefulWidget {
  const PickLobbyScreen({Key? key}) : super(key: key);

  @override
  _PickLobbyScreenState createState() => _PickLobbyScreenState();
}

class _PickLobbyScreenState extends State<PickLobbyScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
            child: Text("Create Lobby"),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EnterAddressPage()))),
        Container(
          width: double.infinity,
          height: 50,
        ),
        GestureDetector(
          child: Text("Join Lobby"),
        )
      ],
    ));
    // return BlocListener

    // <CounterCubit, int>(
    //   builder: (BuildContext context, int state) {
  }
}

class EnterAddressPage extends StatefulWidget {
  EnterAddressPage({Key? key}) : super(key: key);

  @override
  _EnterAddressPageState createState() => _EnterAddressPageState();
}

class _EnterAddressPageState extends State<EnterAddressPage> {
  final List<Widget> locationWidgets = [];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: double.infinity),
            TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a search term',
                ),
                onChanged: (String value) => _fetchSuggestions(value)),
            GestureDetector(
                child: Center(
                    child: Container(
                  width: double.infinity,
                  height: 50,
                  child: Center(child: Text("Use Current Location")),
                )),
                onTap: () => _useCurrentLocation()),
            Expanded(
              child: ListView.builder(
                itemCount: locationWidgets.length,
                itemBuilder: (BuildContext context, int index) {
                  return locationWidgets[index];
                },
              ),
            ),
          ]),
    ));
  }

  Future<void> _fetchSuggestions(String input) async {
    const String lang = "en";
    final String sessionToken = const Uuid().v4();
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&key=$GOOGLE_MAPS_KEY&sessiontoken=$sessionToken';
    final response = await Client().get(request);

    locationWidgets.clear();

    for (int i = 0; i < min(response['predictions'].length, 10); i++) {
      final location = response['predictions'][i];
      Widget locationWidget = _locationWidget(location);
      locationWidgets.add(locationWidget);
      setState(() {});
    }
  }

  Future<void> _useCurrentLocation() async {
    final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

    LocationPermission permission = await _geolocatorPlatform.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    // var addresses = await Geocoder.local.findAddressesFromCoordinates(
    //     new Coordinates(_currentPosition.latitude, _currentPosition.longitude));

    // print(addresses);
  }

  Widget _locationWidget(Map location) {
    return GestureDetector(
        child: Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          child: Center(child: Text("${location["description"]}")),
        ),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => LobbyPage(isHost: true))));
  }
}

class LobbyPage extends StatefulWidget {
  final bool? isHost;

  LobbyPage({@required this.isHost, Key? key}) : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _loadLobby(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: double.infinity,
                      ),
                      GestureDetector(child: Text("Continue"), onTap: () {}),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }));
  }

  Future<void> _loadLobby() async {
    if (widget.isHost!) {
      // await start session
    } else {
      // await get friends
    }
  }
}
