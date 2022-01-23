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
    print(response);
    return json.decode(response);
  }
}

class FirebaseListener {
  FirebaseListener() : super() {
    _startListening();
  }

  final joinController = StreamController<Map>.broadcast();
  final startController = StreamController<Map>.broadcast();
  final finishController = StreamController<Map>.broadcast();

  Stream<Map> get joinStream => joinController.stream;
  Stream<Map> get startStream => startController.stream;
  Stream<Map> get finishStream => finishController.stream;

  void dispose() {}

  Future<void> _startListening() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      Map data = json.decode(event.notification!.body!.toString());
      print(data);
      // print(event.notification!.title!);
      if (event.notification!.title! == "join") {
        // print("join");
        joinController.sink.add(data);
      } else if (event.notification!.title! == "start") {
        // print("start");
        startController.sink.add(data);
      } else if (event.notification!.title! == "finish") {
        // print("finish");
        finishController.sink.add(data);
      }
    });
  }
}

class Restaurant {
  late String address;
  late String distance;
  late int numRatings;
  late int priceLevel;
  late String name;
  late double rating;
  late int id;
  late List<String> pictures;

  Restaurant.fromJson(Map json, int id) {
    this.address = json["address"];
    this.distance = json["distance"];
    this.numRatings = int.parse(json["num_ratings"]);
    this.priceLevel = int.parse(json["price_level"]);
    this.name = json["name"];
    this.rating = double.parse(json["rating"]);
    this.id = id;

    this.pictures = [
      'https://picsum.photos/250?image=9',
      'https://picsum.photos/250?image=10',
      'https://picsum.photos/250?image=11',
    ];
  }
}

// "{address: 128 Pierce St, West Lafayette, IN 47906, USA, distance: 0.3 mi, numRatings: 26, price_level: 2, name: NO 2 ASIAN KITCHEN, rating: 3.3}"

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
            print(sessionId);
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
    sessionId = _controllerSessionId.text;
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
    _listenForRestaurants(context);
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
                onTap: () => Client().post("session/$sessionId/start", {})),
        ],
      ),
    ));
  }

  Future<void> _listenForFriends() async {
    firebaseListener.joinStream.listen((event) {
      widget.names.add(event["name"]);
      setState(() {});
    });
  }

  Future<void> _listenForRestaurants(BuildContext context) async {
    firebaseListener.startStream.listen((event) {
      List<Restaurant> restaurants = [];
      // List<Map> restaurantMaps = event["restaruants"];
      print(event);
      print(event["restaurants"]);
      for (int i = 0; i < event["restaurants"].length; i++) {
        Restaurant restaurant = Restaurant.fromJson(event["restaurants"][i], i);
        restaurants.add(restaurant);
      }

      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RestaurantsListPage(restaurants: restaurants)));
    });
  }
}

class RestaurantsListPage extends StatefulWidget {
  final List<Restaurant>? restaurants;

  RestaurantsListPage({Key? key, @required this.restaurants}) : super(key: key);

  @override
  _RestaurantsListPageState createState() => _RestaurantsListPageState();
}

class _RestaurantsListPageState extends State<RestaurantsListPage> {
  int restaurantIndex = 0;
  int pictureId = 0;
  bool acceptTaps = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(pictureId);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
              padding: const EdgeInsets.all(60),
              child: _restaurantWidget(widget.restaurants![restaurantIndex])),
          Column(children: [
            Row(children: [
              GestureDetector(
                  child: Container(
                      width: .5 * width,
                      height: .5 * height,
                      color: Colors.red.withOpacity(.3)),
                  onTap: () {
                    if (acceptTaps) {
                      acceptTaps = false;
                      pictureId = max(pictureId - 1, 0);

                      setState(() {});
                      acceptTaps = true;
                    }
                  }),
              GestureDetector(
                  child: Container(
                      width: .5 * width,
                      height: .5 * height,
                      color: Colors.green.withOpacity(.3)),
                  onTap: () {
                    if (acceptTaps) {
                      acceptTaps = false;
                      pictureId = min(
                          pictureId + 1,
                          widget.restaurants![restaurantIndex].pictures.length -
                              1);
                      setState(() {});
                      acceptTaps = true;
                    }
                  })
            ]),
            Row(
              children: [
                GestureDetector(
                    child: Container(
                        width: .5 * width,
                        height: .5 * height,
                        color: Colors.blue.withOpacity(.3)),
                    onTap: () {
                      if (acceptTaps) {
                        acceptTaps = false;
                        _sendDecisionToBackend(
                            widget.restaurants![restaurantIndex], true);
                        acceptTaps = true;
                      }
                    }),
                GestureDetector(
                    child: Container(
                        width: .5 * width,
                        height: .5 * height,
                        color: Colors.yellow.withOpacity(.3)),
                    onTap: () {
                      if (acceptTaps) {
                        acceptTaps = false;
                        _sendDecisionToBackend(
                            widget.restaurants![restaurantIndex], true);
                      }
                    })
              ],
            )
          ])
        ],
      ),
    );
  }

  Widget _restaurantWidget(Restaurant restaurant) {
    return Column(
      children: [
        Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  image: NetworkImage(restaurant.pictures[pictureId])),
            ),
            height: 360,
            width: 240),
        Column(
          children: [
            Text(restaurant.name),
            Text(restaurant.address),
            Text(restaurant.distance),
            Text("${restaurant.numRatings}"),
            Text("${restaurant.priceLevel}"),
            Text("${restaurant.rating}")
          ],
        )
      ],
    );
  }

  Future<void> _sendDecisionToBackend(Restaurant restaurant, bool like) async {
    await Client().post("session/$sessionId/restaurants/${restaurant.id}",
        {"like": like.toString()});
    pictureId = 0;
    restaurantIndex++;
    if (restaurantIndex == widget.restaurants!.length) {
      await Client().post("session/$sessionId/finish", {"name": "name"});
      print("Done");
    } else {
      setState(() {});
    }
  }
}

// {"restaurants": [{"address": "135 S Chauncey Ave #2G, West Lafayette, IN 47906, USA", "distance": "0.5 mi", "num_ratings": "116", "price_level": "2", "name": "Hala's Grill", "rating": "4.7"}, {"address": "135 S Chauncey Ave # 2C, West Lafayette, IN 47906, USA", "distance": "0.5 mi", "num_ratings": "337", "price_level": "2", "name": "Basil Thai Restaurant", "rating": "4.1"}]}