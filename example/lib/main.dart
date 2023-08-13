import 'package:flutter/material.dart';
import 'package:flutter_leaf/flutter_leaf.dart';
import 'package:flutter_leaf/state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterLeafState state = FlutterLeafState.disconnected;

  final _proxyController =
      TextEditingController(text: "socks://lisi:abc123@192.168.1.9:7890");

  @override
  void initState() {
    super.initState();
    initLeaf();
  }

  void initLeaf() async {
    FlutterLeaf.prepare();
    state = await FlutterLeaf.currentState;
    FlutterLeaf.onStateChanged.listen((s) => setState(() => state = s));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Leaf app'),
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'State: $state',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            TextFormField(
              controller: _proxyController,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                state == FlutterLeafState.disconnected
                    ? ElevatedButton(
                        onPressed: () {
                          FlutterLeaf.connect(proxy: _proxyController.text);
                        },
                        child: const Text('Connect'),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          FlutterLeaf.disconnect();
                        },
                        child: const Text('Disconnect'),
                      ),
                ElevatedButton(
                  onPressed: state != FlutterLeafState.connected
                      ? null
                      : () {
                          FlutterLeaf.switchProxy(proxy: _proxyController.text);
                        },
                  child: const Text('Switch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
