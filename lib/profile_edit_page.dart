import 'brew_data_handler.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final BrewChartData brewChartData;

  const EditProfilePage({super.key, required this.brewChartData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit brew profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
            ),
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                if (controller.text != '') {
                  widget.brewChartData.saveProfile(controller.text);
                }
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
