import 'dart:io'; // used for Plattform identification

import 'package:app/model/strike.dart';

import 'package:app/page/about/about.dart';
import 'package:app/page/feed/feed.dart';
import 'package:app/page/info/info.dart';
import 'package:app/page/map/map.dart';
import 'package:app/service/api.dart';

import 'package:app/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  await initializeDateFormatting('de_DE', null);

  api = ApiService();

  await api.loadConfig();

  runApp(App());
}

class App extends StatelessWidget {
  ThemeData _buildThemeData(Brightness brightness) {
    var _accentColor = Color(0xff70c2eb);

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
    return themeData;
  }

  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => _buildThemeData(brightness),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'FFF App DE',
          home: Home(),
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

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  void subToAll() async {
    Box box = Hive.box('data');
    for (String cat in feedCategories) {
      await FirebaseMessaging().subscribeToTopic('feed_$cat');
      box.put('feed_$cat', true);
    }
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  initState() {
    if (Hive.box('data').get('firstStart') ?? true) {
      if (Platform.isIOS) {
        _firebaseMessaging.requestNotificationPermissions();
        _firebaseMessaging.configure();
      }
      subToAll();
      Hive.box('data').put('firstStart', false);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_currentIndex),
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
        return InfoPage();
      case 3:
        return AboutPage();
      default:
        return Container();
    }
  }
}
