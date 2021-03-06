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

Widget backButton = Container(
  margin: EdgeInsets.only(right: 8),
  child: Image.asset(
    "assets/back.PNG",
    height: 40,
    width: 30,
    scale: 1.6,
  ),
);

const Color RED = Color(0xffEA1B25);
const Color LIGHTGREY = Color(0xfffafafa);
const Color GREY = Color(0xffEFEFEF);
const Color BLACK = Color(0xff3F3F3F);
const Color DARKGREY = Color(0xff898888);

const String GOOGLE_MAPS_KEY = "AIzaSyDpSH_gylG1i9lfwE18UUULHMjTyUjeddk";

class Client {
  final String url = "http://172.20.10.10:5000/";

  Future<Map> get(String request, [Map queryParams = const {}]) async {
    return json.decode((await http.get(Uri.parse(request))).body);
  }

  Future<Map> post(String path, Map body) async {
    final response = (await http.post(Uri.parse(url + path), body: body)).body;
    // print(response);
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
      // print(data);
      // print(event.notification!.title!);
      if (event.notification!.title! == "user_join") {
        // print("join");
        joinController.sink.add(data);
      } else if (event.notification!.title! == "start") {
        // print("start");
        startController.sink.add(data);
      } else if (event.notification!.title! == "done") {
        print("finish");
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
  late var rating;
  late int id;
  late List<dynamic> photos;

  Restaurant.fromJson(Map json, int id) {
    this.address = json["address"];
    this.distance = json["distance"];
    this.numRatings = json["num_ratings"];
    this.priceLevel = json["price_level"];
    this.name = json["name"];
    this.rating = json["rating"];
    this.id = id;
    this.photos = json["photos"];
  }
}

// "{address: 128 Pierce St, West Lafayette, IN 47906, USA, distance: 0.3 mi, numRatings: 26, price_level: 2, name: NO 2 ASIAN KITCHEN, rating: 3.3}"

late FirebaseListener firebaseListener;
late String sessionId;
late dynamic username;

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(),
        Container(
            child: Transform.translate(
                offset: Offset(23, 0),
                child: Image.asset(
                  "assets/logo_v5_2.png",
                  scale: 1,
                ))),
        Container(
          padding: EdgeInsets.only(bottom: 70),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                    child: _lobbyButton("CREATE A LOBBY", RED, Colors.white),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => EnterHostNamePage()))),
                GestureDetector(
                    child: _lobbyButton(
                        "JOIN A LOBBY", Colors.white, Colors.black),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => EnterGuestNamePage()))),
              ]),
        )
      ],
    ));
    // return BlocListener

    // <CounterCubit, int>(
    //   builder: (BuildContext context, int state) {
  }

  Widget _lobbyButton(String name, Color mainColor, Color outlineColor) {
    return Container(
        width: 260,
        height: 60,
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: mainColor,
          //border: Border.all(color: outlineColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.75),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Center(
            child: Text(name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: outlineColor, fontWeight: FontWeight.bold))));
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
        body: Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
            padding: EdgeInsets.only(top: 60, bottom: 20),
            child: Row(
              children: [
                GestureDetector(
                  child: backButton,
                  onTap: () => Navigator.pop(context),
                ),
                Text("Create a Lobby",
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ],
            )),
        Container(
          margin: EdgeInsets.only(top: 10),
          height: 50,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(15, 10, 10, 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              hintText: 'Your Name',
            ),
          ),
        ),
        GestureDetector(
            child: Container(
                margin: EdgeInsets.only(top: 10),
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: RED,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.75),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Create",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                )),
            onTap: () async {
              var response = await Client().post("session", {
                "name": _controller.text,
                "device_id": await FirebaseMessaging.instance.getToken()
              });
              username = _controller.text;
              sessionId = response["session_id"];
              // print(sessionId);
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EnterAddressPage()));
            })
      ]),
    ));
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
        body: Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    padding: EdgeInsets.only(top: 60, bottom: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          child: backButton,
                          onTap: () => Navigator.pop(context),
                        ),
                        Text("Join a Lobby",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold)),
                      ],
                    )),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  height: 50,
                  child: TextField(
                    controller: _controllerName,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(15, 10, 10, 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Your Name',
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  height: 50,
                  child: TextField(
                    controller: _controllerSessionId,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(15, 10, 10, 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Lobby Code',
                    ),
                  ),
                ),
                GestureDetector(
                    child: Container(
                        margin: EdgeInsets.only(top: 10),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: RED,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.75),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset:
                                  Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Join",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        )),
                    onTap: () => _submitData())
              ],
            )));
  }

  Future<void> _submitData() async {
    final String name = _controllerName.text;
    username = name;
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
      padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: double.infinity),
            Container(
              margin: EdgeInsets.only(top: 30),
              height: 50,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: 'Enter your location',
                        contentPadding: const EdgeInsets.only(left: 35),
                      ),
                      onChanged: (String value) =>
                          _fetchSuggestions(value, context)),
                  GestureDetector(
                      child: Container(
                        margin: EdgeInsets.only(right: 8),
                        child: Image.asset(
                          "assets/back.PNG",
                          height: 40,
                          width: 30,
                          scale: 1.8,
                        ),
                      ),
                      onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            GestureDetector(
                child: Stack(alignment: Alignment.centerLeft, children: [
                  Container(
                      margin: EdgeInsets.only(top: 10),
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(width: .5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 35,
                          top: 15,
                          bottom: 15,
                        ),
                        child: Text("Use Current Location",
                            style: TextStyle(color: RED)),
                      )),
                  Container(
                      height: 30,
                      padding: EdgeInsets.only(
                        top: 4,
                        left: 8,
                        bottom: 0,
                      ),
                      child: Image.asset("assets/bytesize_location.png")),
                ]),
                onTap: () => _useCurrentLocation()),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 20),
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
    await Client().post("session/$sessionId/address", {
      "latitude": _currentPosition.latitude.toString(),
      "longitude": _currentPosition.longitude.toString(),
    });
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LobbyPage(isHost: true)));
  }

  Widget _locationWidget(Map location, BuildContext context) {
    String output = location["description"];
    int offset = 0;
    for (int i = 0; i < output.length; i++) {
      if (i + offset != 0 && (i + offset) % 44 == 0) {
        output = output.substring(0, i + offset) +
            "\n" +
            output.substring(i + offset);
        offset += 1;
      }
    }

    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: GestureDetector(
          child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                    horizontal:
                        BorderSide(color: Colors.grey[400]!, width: .5)),
                // borderRadius: BorderRadius.circular(15),
              ),
              height: 50,
              child: Row(
                children: [
                  Text("${output}", textAlign: TextAlign.left),
                ],
              )),
          onTap: () async {
            var response = await Client().post("/session/$sessionId/address", {
              "address": location["description"],
            });
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LobbyPage(isHost: true)));
          }),
    );
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
  late List<dynamic> names;


  @override
  void initState() {
    super.initState();
    _listenForFriends();
    _listenForRestaurants(context);
  
    names = [username] + widget.names;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: UniqueKey(),
        body: Container(
          padding: EdgeInsets.only(left: 35, right: 35, bottom: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  padding: EdgeInsets.only(top: 60, bottom: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                          child: backButton,
                          onTap: () => Navigator.pop(context)),
                      Text(widget.isHost! ? "Host Lobby" : "Member Lobby",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(left: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: GREY,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 65,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("LOBBY CODE",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: BLACK,
                                  fontWeight: FontWeight.bold)),
                          Text(sessionId,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, color: DARKGREY))
                        ],
                      ),
                    ],
                  )),
              Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(0, 30, 0, 30),
                  height: 500,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GREY),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.75),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                  child: Column(
                    children: [
                      Row(children: [Container(padding: EdgeInsets.only(top: 15, left: 20), child: Text("Members", style: TextStyle(fontSize: 16)))],),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.only(top: 10),
                          key: UniqueKey(),
                          itemCount: names.length,
                          itemBuilder: (context, index) {
                            print(index);
                            return _guestWidget(names[index]);
                          },
                        ),
                      ),
                    ],
                  )),
              if (widget.isHost!)
                GestureDetector(
                    child: Container(
                        margin: EdgeInsets.only(top: 10),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: RED,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.75),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset:
                                  Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Start",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        )),
                    onTap: () => Client().post("session/$sessionId/start", {})),
            ],
          ),
        ));
  }

  Widget _guestWidget(String name) {
    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
      child: Container(
        width: double.infinity,
        height: 40,
        padding: EdgeInsets.only(left: 30),
        decoration: BoxDecoration(
          color: LIGHTGREY,
          border: Border.all(color: LIGHTGREY),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
              textAlign: TextAlign.start,
              style: TextStyle(color: BLACK, fontSize: 20, fontWeight: FontWeight.w600)
      ),
          ],
        )),
    );
  }

  Future<void> _listenForFriends() async {
    firebaseListener.joinStream.listen((event) {
      setState(() {
        names = names + [event["name"]];
      });
    });
  }

  Future<void> _listenForRestaurants(BuildContext context) async {
    firebaseListener.startStream.listen((event) async {
      var response =
          await Client().get(Client().url + "session/$sessionId/restaurants");

      List<Restaurant> restaurants = [];

      for (int i = 0; i < response["restaurants"].length; i++) {
        Restaurant restaurant =
            Restaurant.fromJson(response["restaurants"][i], i);
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              children: [
                Container(child: Image.asset("assets/v5.png")),
                _restaurantWidget(),
                _selectionWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantWidget() {
    String priceLevel = "\$" * widget.restaurants![restaurantIndex].priceLevel;
    double width = MediaQuery.of(context).size.width;
    double height = 560;
    Restaurant restaurant = widget.restaurants![restaurantIndex];
    String pictureUrl =
        "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${restaurant.photos[pictureId]}&key=$GOOGLE_MAPS_KEY";
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Stack(
        children: [
          Container(
              child: Container(
            height: height,
            width: double.infinity,
            child: Column(
              children: [
                Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          image: NetworkImage(pictureUrl)),
                    ),
                    height: 440,
                    width: double.infinity),
                Container(
                  width: width - 40,
                  height: 95,
                  padding:
                      EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          "${restaurant.rating} (${restaurant.numRatings} reviews)",
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14)),
                      Text(restaurant.distance,
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14)),
                      Text("$priceLevel", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                )
              ],
            ),
          )),
          Row(children: [
            GestureDetector(
                child: Container(
                    width: .5 * width - 20,
                    height: height,
                    color: Colors.red.withOpacity(0)),
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
                    width: .5 * width - 20,
                    height: height,
                    color: Colors.green.withOpacity(0)),
                onTap: () {
                  if (acceptTaps) {
                    acceptTaps = false;
                    pictureId = min(pictureId + 1,
                        widget.restaurants![restaurantIndex].photos.length - 1);
                    setState(() {});
                    acceptTaps = true;
                  }
                })
          ]),
        ],
      ),
    );
  }

  Widget _selectionWidget() {
    double width = MediaQuery.of(context).size.width;
    double height = 100;
    return Container(
      height: height,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        GestureDetector(
            child: Container(
                height: height,
                width: width / 2 - 20,
                padding: EdgeInsets.only(left: 60, right: 60),
                child: Container(child: Image.asset("assets/trash.png"))),
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
                height: height,
                width: width / 2 - 20,
                padding: EdgeInsets.only(left: 60, right: 60),
                child: Container(child: Image.asset("assets/utensils.png"))),
            onTap: () {
              if (acceptTaps) {
                acceptTaps = false;
                _sendDecisionToBackend(
                    widget.restaurants![restaurantIndex], true);
                acceptTaps = true;
              }
            })
      ]),
    );
  }

  Future<void> _sendDecisionToBackend(Restaurant restaurant, bool like) async {
    await Client().post("session/$sessionId/restaurants/${restaurant.id}",
        {"like": like.toString()});
    pictureId = 0;
    restaurantIndex++;
    if (restaurantIndex == widget.restaurants!.length) {
      await Client().post("session/$sessionId/finish", {"name": "name"});
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => WaitingScreen()));
    } else {
      setState(() {});
    }
  }
}

class WaitingScreen extends StatefulWidget {
  WaitingScreen({Key? key}) : super(key: key);

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    _listenToFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Text("Waiting for other diners..."),
        ),
      ),
    );
  }

  Future<void> _listenToFirebase() async {
    print("starting");
    firebaseListener.finishStream.listen((event) async {
      print("hello there");
      var response = await Client()
          .get(Client().url + "/session/$sessionId/restaurants/ranks");
      var rankings = response["ranking"];
      print("got rankings");

      List<Restaurant> restaurants = [];
      for (int i = 0; i < rankings.length; i++) {
        restaurants.add(Restaurant.fromJson(rankings[i], i));
      }
      print("made restaurants list");

      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ResultsPage(restaurants: restaurants)));
    });
  }
}

class ResultsPage extends StatefulWidget {
  final List<Restaurant>? restaurants;
  ResultsPage({Key? key, @required this.restaurants}) : super(key: key);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(width: double.infinity),
        Container(child: Image.asset("assets/v5.png")),
        Container(
            height: 500,
            child: ListView.builder(
                itemCount: widget.restaurants!.length,
                itemBuilder: (context, index) {
                  return _restaurantWidget(widget.restaurants![index]);
                }))
      ]),
    ));
  }

  Widget _restaurantWidget(Restaurant restaurant) {
    String priceLevel = "\$" * restaurant.priceLevel; 
    return Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: LIGHTGREY,
          border: Border.all(color: LIGHTGREY),
          borderRadius: BorderRadius.circular(40)
        ),
        child: Column(
          children: [
            Container(
                child: Text(restaurant.name,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(
                child: Text(
                    "${restaurant.rating} (${restaurant.numRatings} reviews)",
                    style: TextStyle(fontSize: 14))),
            Container(
                child:
                    Text(restaurant.distance, style: TextStyle(fontSize: 14))),
            Container(
                child: Text("${priceLevel}",
                    style: TextStyle(fontSize: 14))),
          ],
        ));
  }
}


// {"restaurants": [{"address": "135 S Chauncey Ave #2G, West Lafayette, IN 47906, USA", "distance": "0.5 mi", "num_ratings": "116", "price_level": "2", "name": "Hala's Grill", "rating": "4.7"}, {"address": "135 S Chauncey Ave # 2C, West Lafayette, IN 47906, USA", "distance": "0.5 mi", "num_ratings": "337", "price_level": "2", "name": "Basil Thai Restaurant", "rating": "4.1"}]}