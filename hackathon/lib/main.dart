import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

// fc0bb8

const String GOOGLE_MAPS_KEY = "AIzaSyDpSH_gylG1i9lfwE18UUULHMjTyUjeddk";

class Client {
  final String url = "http://172.20.10.10:5000/";

  Future<Map> get(String request, [Map queryParams = const {}]) async {
    return json.decode((await http.get(Uri.parse(request))).body);
  }

  Future<Map> post(String path, Map body) async {
    final response = (await http.post(Uri.parse(url + path), body: body)).body;
    return json.decode(response);
  }
}

class FirebaseListener {
  FirebaseListener() : super() {
    _startListening();
  }

  final friendsController = StreamController<Map>.broadcast();
  final doneController = StreamController<Map>.broadcast();

  Stream<Map> get friendsStream => friendsController.stream;
  Stream<Map> get doneStream => doneController.stream;

  void dispose() {
    friendsController.close();
    doneController.close();
  }

  Future<void> _startListening() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      Map data = json.decode(event.notification!.body!.toString());
      if (event.notification!.title! == "friends") {
        friendsController.sink.add(data);
      } else if (event.notification!.title! == "done") {
        doneController.sink.add(data);
      }
    });
  }
}

late FirebaseListener firebaseListener;
late String sessionId;

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
          future: _setupFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const PickLobbyScreen();
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Future<void> _setupFirebase() async {
    await Firebase.initializeApp();
    firebaseListener = FirebaseListener();
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
                MaterialPageRoute(builder: (context) => EnterHostNamePage()))),
        Container(
          width: double.infinity,
          height: 50,
        ),
        GestureDetector(
            child: Text("Join Lobby"),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EnterGuestNamePage()))),
      ],
    ));
    // return BlocListener

    // <CounterCubit, int>(
    //   builder: (BuildContext context, int state) {
  }
}

class EnterHostNamePage extends StatefulWidget {
  EnterHostNamePage({Key? key}) : super(key: key);

  @override
  _EnterHostNamePageState createState() => _EnterHostNamePageState();
}

class _EnterHostNamePageState extends State<EnterHostNamePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextField(
        controller: _controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter a search term',
        ),
      ),
      GestureDetector(
          child: Center(
            child: Text("Enter"),
          ),
          onTap: () async {
            var response = await Client().post("session", {
              "name": _controller.text,
              "device_id": await FirebaseMessaging.instance.getToken()
            });
            sessionId = response["session_id"];
            // print("session id: $sessionId");
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EnterAddressPage()));
          })
    ]));
  }
}

class EnterGuestNamePage extends StatefulWidget {
  EnterGuestNamePage({Key? key}) : super(key: key);

  @override
  _EnterGuestNamePageState createState() => _EnterGuestNamePageState();
}

class _EnterGuestNamePageState extends State<EnterGuestNamePage> {
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerSessionId = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
            controller: _controllerName,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Name',
            )),
        TextField(
            controller: _controllerSessionId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Session ID',
            )),
        GestureDetector(
            child: Container(
                width: double.infinity,
                height: 50,
                child: const Center(child: Text("Enter"))),
            onTap: () => _submitData())
      ],
    ));
  }

  Future<void> _submitData() async {
    final String name = _controllerName.text;
    final String sessionId = _controllerSessionId.text;
    final Map data = await Client().post("session/$sessionId", {
      "name": name,
      "device_id": await FirebaseMessaging.instance.getToken(),
    });
    List<dynamic> names = data["names"];
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LobbyPage(isHost: false, names: data["names"])));
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
                onChanged: (String value) => _fetchSuggestions(value, context)),
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

  Future<void> _fetchSuggestions(String input, BuildContext context) async {
    const String lang = "en";
    final String sessionToken = const Uuid().v4();
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&key=$GOOGLE_MAPS_KEY&sessiontoken=$sessionToken';
    final response = await Client().get(request);

    locationWidgets.clear();

    for (int i = 0; i < min(response['predictions'].length, 10); i++) {
      final location = response['predictions'][i];
      Widget locationWidget = _locationWidget(location, context);
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
    // await Client().post()
  }

  Widget _locationWidget(Map location, BuildContext context) {
    return GestureDetector(
        child: Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          child: Center(child: Text("${location["description"]}")),
        ),
        onTap: () async {
          var response = await Client().post("/session/$sessionId/address", {
            "address": location["description"],
          });
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => LobbyPage(isHost: true)));
        });
  }
}

class LobbyPage extends StatefulWidget {
  final bool? isHost;
  final List<dynamic> names;

  LobbyPage({@required this.isHost, this.names = const [], Key? key})
      : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  @override
  void initState() {
    super.initState();
    _listenForFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.infinity,
          ),
          Expanded(
              child: ListView.builder(
            itemCount: widget.names.length,
            itemBuilder: (context, snapshot) {
              return Text(widget.names[snapshot]);
            },
          )),
          if (widget.isHost!)
            GestureDetector(
                child: Text("Continue"),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => RestaurantsListPage()))),
        ],
      ),
    ));
  }

  Future<void> _listenForFriends() async {
    print("listening... ...");
    firebaseListener.friendsStream.listen((event) {
      print(event["name"]);
      widget.names.add(event["name"]);
      setState(() {});
    });
  }
}

class RestaurantsListPage extends StatefulWidget {
  RestaurantsListPage({Key? key}) : super(key: key);

  @override
  _RestaurantsListPageState createState() => _RestaurantsListPageState();
}

class _RestaurantsListPageState extends State<RestaurantsListPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
