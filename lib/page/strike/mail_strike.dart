import 'package:app/app.dart';
import 'package:flutter/rendering.dart';

import 'mail_strike_submit.dart';

class MailStrikePage extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MailStrikePage> {
  final _formKey = GlobalKey<FormState>();

  void _submitButton() {
    if (_formKey.currentState.validate()) {
      // TODO: Implement API call to get info by plz
      // electionDistrict = api.getElectionDistrictByPlz(plz)
      var electionDistrict = "abc";

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MailStrikeSubmitPage(electionDistrict: electionDistrict)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bailout Mail Aktion'),
      ),
      body: ListView(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          /* Image.network(
            'https://app.fffutu.re/img/instagram_instructions.jpg',
          ), */
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Text(
              '''Wähle einen Politiker deines Landkreises aus und sende ihm eine Mail. Wir haben für dich bereits alle Informationen gesammelt und einen Text vorbereitet. Du musst nur noch einen Politiker auswählen und die Email absenden.''',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'PLZ eingeben',
                      border: OutlineInputBorder(),
                    ),

                    // The validator receives the text that the user has entered.
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'PLZ nicht gefunden';
                      }
                      return null;
                    },
                  ),
                ),
                RaisedButton(
                  onPressed: _submitButton,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}