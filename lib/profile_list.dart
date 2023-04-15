import 'package:flutter/material.dart';
import 'package:smart_scale/main.dart';
import 'brew_data_handler.dart';
import 'package:provider/provider.dart';

class ProfileList extends StatelessWidget {
  const ProfileList({super.key});

  @override
  Widget build(BuildContext context) {
    var brewChartData = Provider.of<BrewChartData>(context, listen: false);
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: brewChartData.getAllProfiles(),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(snapshot.data![index]['name']),
                      subtitle: Text(snapshot.data![index]['date_created']),
                      onTap: () {
                        brewChartData
                            .loadGhostLine(snapshot.data![index]['name']);
                        Provider.of<PageState>(context, listen: false)
                            .changePage(0, 'Live Chart');
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
