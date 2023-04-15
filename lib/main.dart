import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_scale/profile_edit_page.dart';
import 'ble_handler.dart';
import 'brew_data_handler.dart';
import 'chart.dart';
import 'profile_list.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => BLEDataHandler()),
        ChangeNotifierProxyProvider<BLEDataHandler, BrewChartData>(
          create: (_) => BrewChartData(bleHandler: BLEDataHandler()),
          update: (_, bleHandler, __) => BrewChartData(bleHandler: bleHandler),
        ),
        ChangeNotifierProvider(create: (_) => PageState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.bottom]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'Coffee profiler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePg(),
    );
  }
}

class PageState extends ChangeNotifier {
  int _currentPage = 0;
  String _currentPageName = 'Home';

  int get currentPage => _currentPage;
  String get currentPageName => _currentPageName;

  void changePage(int pageIndex, String pageName) {
    _currentPage = pageIndex;
    _currentPageName = pageName;
    notifyListeners();
  }
}

class HomePg extends StatelessWidget {
  const HomePg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const pages = [LiveChart(), ProfileList()];
    return Consumer<PageState>(
      builder: (context, pageState, _) => Scaffold(
        body: pages[pageState.currentPage],
        drawer: buildDrawer(context, pageState),
      ),
    );
  }

  Drawer buildDrawer(BuildContext context, PageState pageState) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color.fromARGB(255, 0, 47, 85),
                  Colors.grey,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: HeaderContent(),
          ),
          buildDrawerItem(context, 'Live Chart', 0, pageState),
          buildDrawerItem(context, 'Profile List', 1, pageState),
          buildDrawerItem(context, 'Settings', 2, pageState),
        ],
      ),
    );
  }

  ListTile buildDrawerItem(
      BuildContext context, String title, int index, PageState pageState) {
    return ListTile(
      title: Text(title),
      onTap: () {
        pageState.changePage(index, title);
        Navigator.pop(context);
      },
    );
  }
}

class HeaderContent extends StatelessWidget {
  const HeaderContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconData(0xe178, fontFamily: 'MaterialIcons'),
              size: 40.0,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'Coffee profiler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        Padding(padding: EdgeInsets.all(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SaveButton(),
            Padding(padding: EdgeInsets.only(left: 15)),
            BluetoothConnector(),
          ],
        ),
      ],
    );
  }
}

class BluetoothConnector extends StatefulWidget {
  const BluetoothConnector({super.key});

  @override
  State<BluetoothConnector> createState() => _BluetoothConnectorState();
}

class _BluetoothConnectorState extends State<BluetoothConnector> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BLEDataHandler>(
      builder: (context, bleHandler, _) {
        Color buttonColor = bleHandler.isConnected ? Colors.green : Colors.red;
        return InkWell(
          onTap: () async {
            var showSnackBar = ScaffoldMessenger.of(context);
            if (bleHandler.isConnected) {
              showSnackBar.showSnackBar(
                const SnackBar(content: Text('Disconnecting...')),
              );
              bool success = await bleHandler.disconnect();
              setState(() {
                buttonColor = success ? Colors.red : Colors.green;
              });
              if (!success) {
                showSnackBar.showSnackBar(
                  const SnackBar(content: Text('Failed to disconnect')),
                );
              } else {
                showSnackBar.showSnackBar(
                  const SnackBar(content: Text('Disconnected')),
                );
              }
            } else {
              showSnackBar.showSnackBar(
                const SnackBar(content: Text('Connecting...')),
              );
              bool success = await bleHandler.connect();
              setState(() {
                buttonColor = success ? Colors.green : Colors.red;
              });
              if (!success) {
                showSnackBar.showSnackBar(
                  const SnackBar(content: Text('Failed to connect')),
                );
              } else {
                showSnackBar.showSnackBar(
                  const SnackBar(content: Text('Connected')),
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: buttonColor, // Use color here for the round button
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12.0),
            child: const Icon(Icons.bluetooth,
                color: Colors.white), // Icon color is not changed
          ),
        );
      },
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        var brewChartData = Provider.of<BrewChartData>(context, listen: false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditProfilePage(brewChartData: brewChartData),
          ),
        );
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.purple),
        elevation: MaterialStateProperty.all<double>(5.0), // add some shadow
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        ),
      ),
      icon: const Icon(Icons.save, color: Colors.white),
      label: const Text(
        'Save Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
