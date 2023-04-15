import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'ble_handler.dart';
import 'package:provider/provider.dart';
import 'brew_data_handler.dart';
import 'dart:math';
import 'package:wakelock/wakelock.dart';

class LiveChart extends StatelessWidget {
  const LiveChart({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final brewChartData = Provider.of<BrewChartData>(context);

    return Stack(children: [
      Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          )),
      Center(
        child: LiveChartMain(
          brewChartData: brewChartData,
        ),
      ),
    ]);
  }
}

class LiveChartMain extends StatefulWidget {
  final BrewChartData brewChartData;

  const LiveChartMain({super.key, required this.brewChartData});

  @override
  State<LiveChartMain> createState() => _LiveChartMainState();
}

class _LiveChartMainState extends State<LiveChartMain> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.only(top: 5)),
        InfoBar(brewChartData: widget.brewChartData),
        Padding(padding: EdgeInsets.only(top: 10)),
        Container(
            color: Colors.white,
            child: LiveBrewChart(brewChartData: widget.brewChartData))
      ],
    );
  }
}

class LiveBrewChart extends StatefulWidget {
  final BrewChartData brewChartData;

  const LiveBrewChart({super.key, required this.brewChartData});

  @override
  _LiveBrewChartState createState() => _LiveBrewChartState();
}

class _LiveBrewChartState extends State<LiveBrewChart> {
  _LiveBrewChartState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.brewChartData.brewPoints;
    final pointsGhost = widget.brewChartData.brewPointsGhost;

    // Find the highest x and y values in both lists
    double maxX = max(
      points.isNotEmpty ? points.last.x : 0,
      pointsGhost.isNotEmpty ? pointsGhost.last.x : 0,
    );
    double maxY = max(
        points.isNotEmpty
            ? points
                .reduce((currentMax, spot) =>
                    (spot.y > currentMax.y) ? spot : currentMax)
                .y
            : 0,
        pointsGhost.isNotEmpty
            ? pointsGhost
                .reduce((currentMax, spot) =>
                    (spot.y > currentMax.y) ? spot : currentMax)
                .y
            : 0);

    String formatDuration(Duration d) {
      String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 2.8,
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0, left: 10.0),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY.round() + 10,
                minX: 0,
                maxX: maxX.round() + 10,
                baselineX: 0,
                baselineY: 0,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.grey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.x}: ${barSpot.y}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
                clipData: FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  checkToShowHorizontalLine: (value) => value % 2 == 0,
                  checkToShowVerticalLine: (value) => value % 2 == 0,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  weightLine(points),
                  recepieLine(pointsGhost), // Add pointsGhost to lineBarsData
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    // axisNameWidget: Text('Weight'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      // getTitlesWidget: (value, meta) => (value % 2 == 0
                      //     ? Text(value.toInt().toString())
                      //     : Text('')),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => (value % 2 == 0
                          ? Text(value.toInt().toString())
                          : Text('')),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  LineChartBarData weightLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points.isNotEmpty ? points : [const FlSpot(0, 0)],
      dotData: FlDotData(
        show: false,
      ),
      barWidth: 4,
      color: Colors.green,
      // isCurved: true,
      isStrokeJoinRound: true,
      curveSmoothness: 0.8,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.6),
            Colors.green.withOpacity(0.3),
            // Colors.green.withOpacity(0),
          ],
        ),
      ),
    );
  }

  LineChartBarData recepieLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points.isNotEmpty ? points : [const FlSpot(0, 0)],
      dotData: FlDotData(
        show: false,
      ),
      barWidth: 3,
      color: Colors.blue.withOpacity(0.6),
      isCurved: false,
      isStrokeJoinRound: true,
      curveSmoothness: 0.8,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
            // Colors.green.withOpacity(0),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class InfoBar extends StatefulWidget {
  final BrewChartData brewChartData;

  const InfoBar({super.key, required this.brewChartData});

  @override
  State<InfoBar> createState() => _InfoBarState();
}

class _InfoBarState extends State<InfoBar> {
  _InfoBarState();

  String formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Time: ${widget.brewChartData.brewPointsData.isNotEmpty ? formatDuration(Duration(seconds: widget.brewChartData.brewPointsData.last.x.round())) : "00:00"}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          'Weight: ${widget.brewChartData.currentWeight.toStringAsFixed(1)} g',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Consumer<BLEDataHandler>(builder: (context, bleHandler, _) {
          return ElevatedButton.icon(
            onPressed: () async {
              await bleHandler.sendTareValue(1.0);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            icon: Icon(Icons.restart_alt),
            label: Text(
              'Tare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
        Padding(padding: EdgeInsets.only(left: 8)),
        Consumer<BLEDataHandler>(builder: (context, bleHandler, _) {
          return ElevatedButton.icon(
            onPressed: () async {
              widget.brewChartData.clear();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            icon: Icon(Icons.clear),
            label: Text(
              'Clear',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
        Padding(padding: EdgeInsets.only(left: 8)),
        ElevatedButton.icon(
          onPressed: () {
            widget.brewChartData.stop();
            Wakelock.disable();
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            ),
          ),
          icon: Icon(Icons.stop),
          label: Text(
            'Stop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(padding: EdgeInsets.only(left: 8)),
        ElevatedButton.icon(
          onPressed: () {
            widget.brewChartData.smartStart();
            Wakelock.enable();
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            ),
          ),
          icon: Icon(Icons.play_arrow),
          label: Text(
            'Start',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(padding: EdgeInsets.only(left: 12)),
      ],
    );
  }
}
