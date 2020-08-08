import 'dart:io';

import 'package:app/app.dart';
import 'package:app/model/slogan.dart';
import 'package:app/page/about/about_subpage/slogan.dart';
import 'package:app/util/share.dart';
import 'package:flutter/cupertino.dart';

import 'demofilter.dart';

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future _loadData() async {
    try {
      slogans = await api.getSlogans();

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(
                'Der Inhalt konnte nicht geladen werden, bitte prüfe deine Internetverbindung.')));
    }
  }

  List<Slogan> slogans;

  bool searchActive = false;
  String searchText = '';

  var filterState = FilterState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: Platform.isIOS,
        title: searchActive
            ? TextField(
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: false,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: 'Suchen',
                    hintStyle: TextStyle(color: Colors.white)),
                onChanged: (s) {
                  setState(() {
                    searchText = s;
                  });
                },
              )
            : Text('Demosprüche', semanticsLabel: 'Demosprüche'),
        actions: <Widget>[
          if (slogans != null)
            if (!searchActive)
              IconButton(
                icon: Icon(MdiIcons.filter),
                tooltip: 'Filter Einstellungen',
                onPressed: () async {
                  var newFilterState = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DemoFilterPage(
                        filterState,
                        slogans.fold<Set>(
                            Set(), (a, b) => a..addAll(b.tags.toList())),
                      ),
                    ),
                  );

                  if (newFilterState != null)
                    setState(() {
                      filterState = newFilterState;
                    });
                },
              ),
          if (slogans != null)
            IconButton(
              icon: Icon(searchActive ? Icons.close : MdiIcons.magnify,
                  semanticLabel:
                      searchActive ? 'Suche schließen' : 'Im Feed suchen'),
              onPressed: () {
                setState(() {
                  if (searchActive) {
                    searchText = '';
                    searchActive = false;
                  } else {
                    searchActive = true;
                  }
                });
              },
            ),
        ],
      ),
      body: slogans == null
          ? LinearProgressIndicator()
          : Column(
              children: <Widget>[
                if (filterState.filterActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.yellow,
                    alignment: Alignment.center,
                    child: Text(
                      'Es sind Filter aktiv',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                Expanded(
                  child: searchActive
                      ? _buildListView(text: searchText.toLowerCase())
                      : _buildListView(category: "Alle"),
                ),
              ],
            ),
    );
  }

  Widget _buildListView({String category, String text}) {
    List<Slogan> shownSlogans = List.from(slogans);

    if (filterState.filterActive) {
      if (filterState.onlyShowMarked) {
        var markBox = Hive.box('slogan_mark');
        shownSlogans =
            shownSlogans.where((p) => (markBox.get(p.id) ?? false)).toList();
      }
      if (filterState.onlyShowUnread) {
        var readBox = Hive.box('slogan_read');
        shownSlogans =
            shownSlogans.where((p) => !(readBox.get(p.id) ?? false)).toList();
      }
      if (filterState.shownTags.isNotEmpty) {
        shownSlogans = shownSlogans
            .where((p) =>
                p.tags.firstWhere((s) => filterState.shownTags.contains(s),
                    orElse: () => null) !=
                null)
            .toList();
      }
    }

    if (category != null) {
      shownSlogans = []; //shownSlogans
      //.where((p) => p.tags.indexWhere(t == category) != -1)
      // .toList();
    } else {
      shownSlogans = []; // shownSlogans
      // .where((p) => ((p.title ?? '') +
      //         ' ' +
      //         (p.customExcerpt ?? '') +
      //         p.tags.map((t) => t.name).toString() +
      //         (p.primaryAuthor?.name ?? ''))
      //     .toLowerCase()
      //     .contains(text))
      // .toList();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: shownSlogans.isEmpty
          ? Center(
              child: Text('Keine Ergebnisse'),
            )
          : ListView.separated(
              itemCount: shownSlogans.length,
              itemBuilder: (context, index) {
                return FeedItem(shownSlogans[index]);
              },
              separatorBuilder: (context, index) => Container(
                height: 0.5,
                color: Theme.of(context).hintColor,
              ),
            ),
    );
  }
}

class FeedItem extends StatefulWidget {
  final Slogan item;
  FeedItem(this.item);

  @override
  _FeedItemState createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  Slogan get slogan => widget.item;

  @override
  Widget build(BuildContext context) {
    bool read = Hive.box('slogan_read').get(slogan.id) ?? false;
    bool marked = Hive.box('slogan_mark').get(slogan.id) ?? false;

    var textTheme = Theme.of(context).textTheme;

    if (read) {
      textTheme = textTheme.apply(
        bodyColor: Theme.of(context).hintColor,
      );
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SloganPage(), // TODO: Pass slogan
          ),
        );
        setState(() {});
      },
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: BoxConstraints(minHeight: 32),
                            child: Text(
                              slogan.title,
                              style: textTheme.subhead,
                            ),
                          ),
                          // if (slogan.customExcerpt != null)
                          //   Text(
                          //     slogan.customExcerpt,
                          //     style: textTheme.body1,
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: <Widget>[
                          for (var tag in slogan.tags)
                            Chip(
                              label: Text(
                                tag,
                                style: textTheme.body1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: Platform.isAndroid
                  ? <Widget>[
                      if (marked)
                        Icon(
                          MdiIcons.bookmark,
                          color: Theme.of(context).accentColor,
                          semanticLabel: 'Markierter Artikel',
                        ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          semanticLabel: 'Menü anzeigen',
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text(
                                marked ? 'Markierung entfernen' : 'Markieren'),
                            value: 'mark',
                          ),
                          PopupMenuItem(
                            child: Text('Teilen...'),
                            value: 'share',
                          ),
                          if (read)
                            PopupMenuItem(
                              child: Text('Als ungelesen kennzeichnen'),
                              value: 'unread',
                            ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'mark':
                              setState(() {
                                Hive.box('slogan_mark').put(slogan.id, !marked);
                              });
                              break;
                            case 'share':
                              ShareUtil.shareSlogan(slogan);
                              break;
                            case 'unread':
                              setState(() {
                                Hive.box('slogan_read').put(slogan.id, false);
                              });
                              break;
                          }
                        },
                      ),
                    ]
                  :
                  //iOS adaption (action sheet)
                  <Widget>[
                      if (marked)
                        Icon(
                          MdiIcons.bookmark,
                          semanticLabel: 'Markierter Artikel',
                          color: Theme.of(context).accentColor,
                        ),
                      CupertinoButton(
                        onPressed: () {
                          showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return CupertinoActionSheet(
                                  actions: <Widget>[
                                    CupertinoActionSheetAction(
                                      child: Text(marked
                                          ? 'Markierung entfernen'
                                          : 'Markieren'),
                                      onPressed: () {
                                        setState(() {
                                          Hive.box('slogan_mark')
                                              .put(slogan.id, !marked);
                                        });
                                        Navigator.pop(context, 'Mark');
                                      },
                                    ),
                                    CupertinoActionSheetAction(
                                      child: const Text('Teilen...'),
                                      onPressed: () {
                                        ShareUtil.shareSlogan(slogan);
                                        Navigator.pop(context, 'Share');
                                      },
                                    ),
                                    if (read)
                                      CupertinoActionSheetAction(
                                        child: const Text(
                                            'Als ungelesen kennzeichnen'),
                                        onPressed: () {
                                          setState(() {
                                            Hive.box('slogan_read')
                                                .put(slogan.id, false);
                                          });
                                          Navigator.pop(context, 'Read');
                                        },
                                      )
                                  ],
                                  //cancel button
                                  cancelButton: CupertinoActionSheetAction(
                                    child: const Text('Abbrechen'),
                                    isDefaultAction: true,
                                    onPressed: () {
                                      Navigator.pop(context, 'Cancel');
                                    },
                                  ),
                                );
                              });
                        },
                        child: Icon(CupertinoIcons.ellipsis,
                            color: Theme.of(context).hintColor),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
