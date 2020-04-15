import 'package:app/page/strike/map-netzstreik/add-iframe-page.dart';
import 'package:app/page/strike/map-netzstreik/add-strike-page.dart';
import 'package:app/page/strike/map-netzstreik/netzstreik-api.dart';
import 'package:app/widget/og_social_buttons.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app.dart';
import 'package:latlong/latlong.dart';

/**
 * A map that shows all Strike points for the global Climate strike on 04/24/2020
 */
class MapNetzstreik extends StatefulWidget {
  @override
  _MapNetzstreikState createState() => _MapNetzstreikState();
}

class _MapNetzstreikState extends State<MapNetzstreik> {
  NetzstreikApi netzstreikApi = NetzstreikApi();
  List<StrikePoint> strikePointL = List<StrikePoint>();

  /**
   * The init Method Loads all strike Points.
   */
  @override
  void initState() {
    netzstreikApi.getAllStrikePoints().then((list) {
      if (mounted) {
        setState(() {
          strikePointL = list;
        });
      }
    });

    super.initState();
  }

  /**
   * Generates the Marker for one Strike Point
   */
  Marker _generateMarker(StrikePoint strikePoint) {
    return Marker(
        width: 45.0,
        height: 45.0,
        point: LatLng(strikePoint.lat, strikePoint.lon),
        builder: (context) => new Container(
              child: IconButton(
                icon: Icon(Icons.location_on),
                color: strikePoint.isFeatured
                    ? Theme.of(context).accentColor
                    : Theme.of(context).primaryColor,
                iconSize: 45.0,
                onPressed: () {
                  _showStrikePoint(strikePoint);
                },
              ),
            ));
  }

  /**
   * Genrates a list of Markes of not Features Strike Points
   */
  List<Marker> _getAllNotFeatured() {
    List<Marker> resultL = [];
    for (StrikePoint strikePoint in strikePointL) {
      if (!strikePoint.isFeatured) {
        resultL.add(_generateMarker(strikePoint));
      }
    }
    return resultL;
  }

  /**
   * Generates a list of Markers of all Features Strike Points
   */
  List<Marker> _getAllFeatured() {
    List<Marker> resultL = [];
    for (StrikePoint strikePoint in strikePointL) {
      if (strikePoint.isFeatured) {
        resultL.add(Marker(
            width: 45.0,
            height: 45.0,
            point: LatLng(strikePoint.lat, strikePoint.lon),
            builder: (context) => new Container(
                  child: IconButton(
                    icon: Icon(Icons.location_on),
                    color: Theme.of(context).accentColor,
                    iconSize: 45.0,
                    onPressed: () {
                      _showStrikePoint(strikePoint);
                    },
                  ),
                )));
      }
    }
    return resultL;
  }

  /**
   * Shows a Popup for a Strike point for example if a point is tapped
   */
  void _showStrikePoint(StrikePoint strikePoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            (strikePoint.name == "") ? "Ein Aktivisti*" : strikePoint.name),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text((strikePoint.text == "") ? " " : strikePoint.text),
              SocialButtons(strikePoint, true).build(context),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Streik Karte"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(51.3867, 9.9167),
              zoom: 5.7,
              minZoom: 4,
              maxZoom: 19,
              plugins: [
                MarkerClusterPlugin(),
              ],
            ),
            layers: [
              TileLayerOptions(
                  urlTemplate:
                      'https://mapcache.fridaysforfuture.de/{z}/{x}/{y}.png',
                  tileProvider: CachedNetworkTileProvider()),
              // all Clusters (not featured marker)
              MarkerClusterLayerOptions(
                maxClusterRadius: 120,
                size: Size(40, 40),
                fitBoundsOptions: FitBoundsOptions(
                  padding: EdgeInsets.all(50),
                ),
                markers: _getAllNotFeatured(),
                polygonOptions: PolygonOptions(
                    borderColor: Theme.of(context).primaryColor,
                    color: Colors.black12,
                    borderStrokeWidth: 3),
                builder: (context, markers) {
                  return FloatingActionButton(
                    heroTag: null,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      markers.length.toString(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: null,
                  );
                },
              ),
              // all featured strike Points
              new MarkerLayerOptions(
                markers: _getAllFeatured(),
              ),

              /*    MarkerLayerOptions(
                            ), */
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              color: Color(0xaaffffff),
              padding: const EdgeInsets.all(2.0),

              child: Text(
                '© OpenStreetMap-Mitwirkende',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          //The Expandable Info Text at the Top
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).accentColor,
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              margin: EdgeInsets.all(8.0),
              padding: EdgeInsets.all(8.0),
              child: ExpandableNotifier(
                // <-- Provides ExpandableController to its children
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Expandable(
                    // <-- Driven by ExpandableController from ExpandableNotifier
                    collapsed: ExpandableButton(
                      // <-- Expands when tapped on the cover photo
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Wir streiken weiter',
                            style: Theme.of(context)
                                .textTheme
                                .title
                                .copyWith(color: Colors.black),
                          ),
                          Text(
                              "Wir streiken weiter Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                              )),
                          Center(
                            child: Text(
                                'weiterlesen',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black//Theme.of(context).primaryColor,
                                ),

                            ),
                          ),
                        ],
                      ),
                    ),
                    expanded: ExpandableButton(
                      // <-- Collapses when tapped on
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wir streiken weiter',
                              style: Theme.of(context)
                                  .textTheme
                                  .title
                                  .copyWith(color: Colors.black),
                            ),
                            Text(
                                "Wir streiken weiter Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. ",
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            Center(
                              child: Text("Einklappen",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          ]),
                    ),
                  )
                ]),
              ),
            ),
            FlatButton(
              child: Text("Jetzt mitstreiken",
                  style: Theme.of(context)
                      .textTheme
                      .title
                      .copyWith(color: Colors.white)),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                const url = 'https://actionmap.fridaysforfuture.de/iframe.html';

                launch(url);
                /*Navigator.push(
                  context,
                  //Pushes the Sub Page on the Stack
                  //MaterialPageRoute(builder: (context) => AddStrikePage(netzstreikApi)),
                   // MaterialPageRoute(builder: (context) => AddIFramePage())
                );*/
              },
            )
          ])
        ],
      ),
    );
  }
}
