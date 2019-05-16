import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

class ScatterPlotComboLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  ScatterPlotComboLineChart(this.seriesList, {this.animate});

  /// Creates a [ScatterPlotChart]
  factory ScatterPlotComboLineChart.withElectionsData() {
    return new ScatterPlotComboLineChart(
      _getPollData(),
      animate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(seriesList,
        animate: animate,
        behaviors: [new charts.SeriesLegend()],
        // Configure the default renderer as a point renderer. This will be used
        // for any series that does not define a rendererIdKey.
        //
        // This is the default configuration, but is shown here for
        // illustration.
        defaultRenderer: new charts.PointRendererConfig(),
        // Custom renderer configuration for the line series.
        customSeriesRenderers: [
          new charts.LineRendererConfig(
              // ID used to link series to this renderer.
              customRendererId: 'customLine',
              // Configure the regression line to be painted above the points.
              //
              // By default, series drawn by the point renderer are painted on
              // top of those drawn by a line renderer.
              layoutPaintOrder: charts.LayoutViewPaintOrder.point + 1)
        ]);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<ScatterPolls, DateTime>> _getPollData() {

    
  var polls = new List<pollDatum>();
  var pollsterRatings = new List<String>();

  DateFormat format = new DateFormat("M/d/yy");

    HttpClient client = new HttpClient();
client.getUrl(Uri.parse("https://projects.fivethirtyeight.com/polls-page/president_primary_polls.csv"))
  .then((HttpClientRequest request) {
    return request.close();
  })
  .then((HttpClientResponse response) {
    response
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(new LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.

      List row = line.split(','); // split by comma

      int question_id = int.parse(row[0]);
      String state = row[3];
      String pollster = row[5];
      int sample_size = int.parse(row[12]);
      DateTime start_date = format.parse(row[17]);
      DateTime end_date = format.parse(row[18]);
      String party = row[28];
      String answer = row[29];
      double pct = double.parse(row[31]);

      
      print(int.parse(row[0]));
      print(row[3]);
      print(row[5]);
      print(int.parse(row[12]));
      print(format.parse(row[17]));
      print(format.parse(row[18]));
      print(row[28]);
      print(row[29]);
      print(double.parse(row[31]));

polls.add(new pollDatum(question_id, state, pollster
            ,sample_size, start_date, end_date
            ,party, answer, pct));
    }, onDone: () {
      print('File is now closed.');
    }, onError: (e) {
      print(e.toString());
    });
  });
print(polls);
    final pollScatterData = [
      new ScatterPolls(new DateTime.utc(1989, 11, 9), 5, "Warren"),
      new ScatterPolls(new DateTime.utc(1989, 12, 9), 25, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 1, 9), 75, "Sanders"),
      new ScatterPolls(new DateTime.utc(1990, 2, 9), 225, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 3, 9), 50, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 4, 9), 75, "Sanders"),
      new ScatterPolls(new DateTime.utc(1990, 5, 9), 100, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 6, 9), 150, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 7, 9), 10, "Sanders"),
      new ScatterPolls(new DateTime.utc(1990, 8, 9), 300, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 9, 9), 15, "Warren"),
      new ScatterPolls(new DateTime.utc(1990, 10, 9), 200, "Biden"),
    ];

    var pollLineData = [
      new ScatterPolls(new DateTime.utc(1989, 11, 9), 5, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 2, 20), 15, "Biden"),
      new ScatterPolls(new DateTime.utc(1990, 10, 9), 240, "Biden"),
    ];

    return [
      new charts.Series<ScatterPolls, DateTime>(
        id: 'Biden Polls',
        domainFn: (ScatterPolls polls, _) => polls.pollDate,
        measureFn: (ScatterPolls polls, _) => polls.result,
        data: pollScatterData,
      ),
      new charts.Series<ScatterPolls, DateTime>(
          id: 'Biden Daily Average',
          domainFn: (ScatterPolls polls, _) => polls.pollDate,
          measureFn: (ScatterPolls polls, _) => polls.result,
          data: pollLineData)
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }
}

/// Sample linear data type.
class ScatterPolls {
  final DateTime pollDate;
  final double result;
  final String answer;

  ScatterPolls(this.pollDate, this.result, this.answer);
}

/// Sample linear data type.
class pollDatum {

    final int question_id;
      final String state;
      final String pollster;
      final int sample_size;
      final DateTime start_date;
      final DateTime end_date;
      final String party;
      final String answer;
      final double pct;

  pollDatum(this.question_id, this.state, this.pollster
            ,this.sample_size, this.start_date, this.end_date
            ,this.party, this.answer, this.pct);
}

void main() => runApp(ElectionsApp());

class ElectionsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '2020 Primary Polls',
        home: Scaffold(
          appBar: AppBar(
            title: Text('2020 Primary Polls'),
          ),
          body: new ScatterPlotComboLineChart.withElectionsData(),
        ));
  }
}
