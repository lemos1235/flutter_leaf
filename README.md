# flutter_leaf

A new flutter vpn plugin based on leaf

### Add Dependency 

```yaml
dependencies:

  flutter_leaf:
    git: https://github.com/lemos1235/flutter_leaf.git
```

### Usage

```dart
class _MyAppState extends State<MyApp> {
  late FlutterLeafState state = FlutterLeafState.disconnected;

  late TextEditingController _configContentController;

  @override
  void initState() {
    super.initState();
    initLeaf();
    loadConfigContent();
  }

  void initLeaf() async {
    FlutterLeaf.prepare();
    state = await FlutterLeaf.currentState;
    FlutterLeaf.onStateChanged.listen((s) => setState(() => state = s));
  }

  void loadConfigContent() {
    String configContent = """[General]
      dns-server = 223.5.5.5
      tun-fd = <TUN-FD>
      loglevel = info
      [Proxy]
      Direct = direct
      SOCKS5 = socks,192.168.1.9,7890
      [Rule]
      FINAL, SOCKS5""";
    final content = configContent.trim().replaceAll(RegExp(r' \s+'), ' ');
    _configContentController = TextEditingController(text: content);
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
            TextField(controller: _configContentController, maxLines: null),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                state == FlutterLeafState.disconnected
                    ? ElevatedButton(
                        onPressed: () {
                          FlutterLeaf.connect(
                              configContent: _configContentController.text);
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
                          FlutterLeaf.switchProxy(
                              configContent: _configContentController.text);
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
```

