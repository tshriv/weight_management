import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weight_management/sign_in.dart';
import 'package:weight_management/sign_in_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
  // init();
}

String? loggedInEmailId = "";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (context) => SignInProvider(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const Auth(),
      ));
}

//Auth Widget
class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
          body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          else if (snapshot.hasData) {
            final provider =
                Provider.of<SignInProvider>(context, listen: false);
            loggedInEmailId = snapshot.data?.email;
            provider.addUserOnFirestoreIfNeeded(loggedInEmailId!);
            return MyHomePage(title: 'Weight Management');
          } else if (snapshot.hasError)
            return Center(
              child: Text("Something went wrong"),
            );
          else
            return SignIn();
        },
      ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final weights = FirebaseFirestore.instance
      .collection("users")
      .doc(loggedInEmailId)
      .collection("weights");
  final TextEditingController name = TextEditingController();
  final TextEditingController weight = TextEditingController();

  Future<void> create([DocumentSnapshot? documentSnapshot]) async {
    await showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: weight,
                  decoration: const InputDecoration(labelText: "Weight"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: const Text('Create'),
                  onPressed: () async {
                    final String name_input = name.text;
                    final double? weight_input = double.tryParse(weight.text);
                    if (name != null) {
                      await weights.add({
                        "name": name_input,
                        "weight": weight_input,
                        "date": DateFormat("dd-MM-yyyy").format(DateTime.now()),
                        "time": DateFormat("hh:mm a").format(DateTime.now())
                      });
                      name.text = "";
                      weight.text = "";
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var allWeightData = [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              logout();
            },
            icon: FaIcon(
              FontAwesomeIcons.signOutAlt,
            ),
            iconSize: 20.0,
          ),
          IconButton(
            onPressed: () {
              showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(allWeightData));
            },
            icon: FaIcon(
              FontAwesomeIcons.search,
            ),
            iconSize: 20,
          ),
        ],
      ),
      body: StreamBuilder(
          stream: weights.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              allWeightData = streamSnapshot.data!.docs;
              return ListView.builder(
                  itemCount: allWeightData.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DocumentSnapshot documentSnapshot =
                        allWeightData[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xff764abc),
                        child: Text(
                          documentSnapshot["weight"].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(documentSnapshot["name"]),
                      subtitle: Text(
                          "${documentSnapshot["date"]} ${documentSnapshot["time"]}"),
                    );
                  });
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => create(),
        tooltip: 'Add New',
        child: const Icon(Icons.add),
      ),
    );
  }

  void logout() {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: Text("Yes"),
      onPressed: () {
        final provider = Provider.of<SignInProvider>(context, listen: false);
        provider.logout();
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Do you want to Logout?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  var allWeightData = [];
  CustomSearchDelegate(allWeightData) {
    this.allWeightData = allWeightData;
  }
  // first overwrite to
  // clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  // second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  // third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    List<QueryDocumentSnapshot<Object?>> matchQuery = [];

    for (var weight in allWeightData) {
      if (weight["name"].toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(weight);
      }
    }
    return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (BuildContext context, int index) {
          final DocumentSnapshot documentSnapshot = matchQuery[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xff764abc),
              child: Text(
                documentSnapshot["weight"].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(documentSnapshot["name"]),
            subtitle:
                Text("${documentSnapshot["date"]} ${documentSnapshot["time"]}"),
          );
        });
  }

  // last overwrite to show the
  // querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    List<QueryDocumentSnapshot<Object?>> matchQuery = [];
    for (var weight in allWeightData) {
      if (weight["name"].toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(weight);
      }
    }
    return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (BuildContext context, int index) {
          final DocumentSnapshot documentSnapshot = matchQuery[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xff764abc),
              child: Text(
                documentSnapshot["weight"].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(documentSnapshot["name"]),
            subtitle:
                Text("${documentSnapshot["date"]} ${documentSnapshot["time"]}"),
          );
        });
  }
}
