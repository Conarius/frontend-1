import 'dart:io'; // used for Plattform identification

import 'package:app/model/strike.dart';

import 'package:app/page/about/about.dart';
import 'package:app/page/feed/feed.dart';
import 'package:app/page/feed/post.dart';
import 'package:app/page/info/info.dart';
import 'package:app/page/map/map.dart';
import 'package:app/page/strike/html_strike_page.dart';
import 'package:app/page/strike/map-netzstreik/netzstreik-api.dart';
import 'package:app/page/strike/strike.dart';
import 'package:app/service/api.dart';

import 'package:app/app.dart';
import 'package:app/service/theme.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model/live_event.dart';
import 'page/intro/video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(OGAdapter());
  Hive.registerAdapter(StrikeAdapter());

  await Hive.openBox('data');

  await Hive.openBox('post_read');
  await Hive.openBox('post_mark');

  await Hive.openBox('subscribed_ogs');

  await Hive.openBox('strikes');

  await Hive.openBox('challenges');

  await initializeDateFormatting('de_DE', null);

  api = ApiService();

  await api.loadConfig();


  api.updateOGs();

  runApp(App());
}

class App extends StatelessWidget {
  ThemeData _buildThemeData(String theme) {
    var _accentColor = Color(0xff70c2eb);

    var brightness =
        ['light', 'sepia'].contains(theme) ? Brightness.light : Brightness.dark;

    var themeData = ThemeData(
      brightness: brightness,
      accentColor: _accentColor,
      primaryColor: Color(0xff1da64a),
      toggleableActiveColor: _accentColor,
      highlightColor: _accentColor,
      buttonColor: _accentColor,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
      ),
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
        buttonColor: _accentColor,
      ),
      textTheme: TextTheme(
        button: TextStyle(color: _accentColor),
      ),
      fontFamily: 'LibreFranklin',
    );

    if (theme == 'sepia') {
      Color backgroundColor = Color(0xffF7ECD5);
      themeData = themeData.copyWith(
        backgroundColor: backgroundColor,
        scaffoldBackgroundColor: backgroundColor,
        dialogBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
      );
    } else if (theme == 'black') {
      Color backgroundColor = Colors.black;
      themeData = themeData.copyWith(
        backgroundColor: backgroundColor,
        scaffoldBackgroundColor: backgroundColor,
        dialogBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
      );
    }

    //sets the Background for the IOs Subtitles depending on the theme Brightness
    if (Platform.isIOS) {
      if (brightness == Brightness.dark) {
        themeData = themeData.copyWith(
            textTheme: themeData.textTheme.copyWith(
                subtitle: themeData.textTheme.subtitle
                    .copyWith(backgroundColor: Colors.grey[800])));
      } else {
        themeData = themeData.copyWith(
            textTheme: themeData.textTheme.copyWith(
                subtitle: themeData.textTheme.subtitle
                    .copyWith(backgroundColor: Colors.grey[100])));
      }
    }
    return themeData;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return AppTheme(
      data: (theme) => _buildThemeData(theme),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'App For Future',
          home: (Hive.box('data').get('intro_done') ?? false)
              ? Home()
              : VideoPage(),
          theme: theme,
        );
      },
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver{
  int _currentIndex = 0;

  void subToAll() async {
    Box box = Hive.box('data');
    for (String cat in feedCategories) {
      await FirebaseMessaging().subscribeToTopic('feed_$cat');
      box.put('feed_$cat', true);
    }
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  Future _handleNotificationOpen(Map<String, dynamic> data) async {
    String type = data['data']['type'];
    String payload = data['data']['payload'];

    await _handleLinkLaunch(type, payload, 'push');
  }

  Future _handleDynamicLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      var parts = deepLink.path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length == 2) _handleLinkLaunch(parts[0], parts[1], 'share');
    }
  }

  Set<String> _launched = {};

  Future _handleLinkLaunch(String type, String payload, String source) async {
    var box = await Hive.openBox('launched_links');

    String key = '$type.$payload.$source';
    if (box.get(key) ?? false || _launched.contains(key)) {
      return;
    }
    _launched.add(key);
    box.put(key, true);

    if (type == 'feed') {
      setState(() {
        _currentIndex = 0;
      });

      var posts = await api.getPosts();

      var post = posts.firstWhere((p) => p.id == payload, orElse: () => null);

      if (post == null) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text('Der Artikel konnte nicht gefunden werden.')));
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostPage(post),
          ),
        );
      }
    } else if (type == 'strike') {
      setState(() {
        _currentIndex = 3;
      });
    }
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state){
    super.didChangeAppLifecycleState(state);
    switch(state){
      case AppLifecycleState.detached:break;
      case AppLifecycleState.inactive:break;
      case AppLifecycleState.paused:break;
      case AppLifecycleState.resumed:_checkForLiveEvent();
    }
  }


  _checkForLiveEvent() async {
    LiveEvent liveEvent = await api.getLiveEvent();
    if (!liveEvent.isActive) {
      return;
    }

    if (!mounted) {
      await Future.delayed(Duration(seconds: 1));
    }
    WidgetBuilder b = (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(8),
        height: 100,
        color: Theme.of(context).accentColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: Text(
                liveEvent.actionText,
                style: TextStyle(
                  color:Colors.black,
                )
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Text("Anschauen",
                      style: Theme.of(context).textTheme.title),
                  onPressed: () {
                    Navigator.pop(context);
                    if(liveEvent.inApp){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HtmlStrikePage()),
                      );
                    }else {
                      _launchURL(liveEvent.actionUrl);
                    }
                  },
                ),
                SizedBox(
                  width: 16,
                ),
                RaisedButton(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Text("Später",
                      style: Theme.of(context).textTheme.title),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      );
    };
    _scaffoldKey.currentState.showBottomSheet(b);
  }

  @override
  initState() {
    _checkForLiveEvent();
    _firebaseMessaging.configure(
      onResume: _handleNotificationOpen,
      onLaunch: _handleNotificationOpen,
    );

    FirebaseDynamicLinks.instance.getInitialLink().then(_handleDynamicLink);

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: _handleDynamicLink,
        onError: (OnLinkErrorException e) async {
          print('onLinkError');
          print(e.message);
        });

    if (Hive.box('data').get('firstStart') ?? true) {
      if (Platform.isIOS) {
        _firebaseMessaging.requestNotificationPermissions();
      }
      subToAll();
      Hive.box('data').put('firstStart', false);
    }
    /*
    Adds a observer importent for the AppLifecycleState
     */
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }
  @override
  void dispose() {
    /*
    Removes a observer importent for the AppLifecycleState
     */
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  var _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          return Column(children: <Widget>[
            Expanded(child: child),
            if (!connected)
              Container(
                color: Theme.of(context).accentColor,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      "Die App ist aktuell offline",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
          ]);
        },
        child: _buildPage(_currentIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted)
            setState(() {
              _currentIndex = index;
            });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.newspaper),
            title: Text('Feed'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            title: Text('Karte'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            title: Text('Netzstreik'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            title: Text('Infos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.accountGroup),
            title: Text('Über uns'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return FeedPage();
      case 1:
        return MapPage();
      case 2:
        return StrikePage();
      case 3:
        return InfoPage();
      case 4:
        return AboutPage();
      default:
        return Container();
    }
  }
}
