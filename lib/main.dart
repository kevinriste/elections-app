import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class ScatterPlotComboLineChart extends StatefulWidget {
    @override
    State createState() => new ScatterPlotComboLineChartState();
}

class ScatterPlotComboLineChartState extends State<ScatterPlotComboLineChart> {
  List<charts.Series> seriesList;
  bool animate = true;

  @override
    void initState() {
      super.initState();
        // This is the proper place to make the async calls
        // This way they only get called once

        // During development, if you change this code,
        // you will need to do a full restart instead of just a hot reload
        
        // You can't use async/await here,
        // We can't mark this method as async because of the @override
        getPollData().then((result) {
          print(result);
            // If we need to rebuild the widget with the resulting data,
            // make sure to use `setState`
            setState(() {
                seriesList = result;
            });
        });
    }

  @override
  Widget build(BuildContext context) {
        if (seriesList == null) {
            // This is what we show while we're loading
            return new Container();
        }
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
}



/// Create one series with sample hard coded data.
Future<List<charts.Series<ScatterPolls, DateTime>>> getPollData() async {
    var polls = new List<PollDatum>();
    //var pollsterRatings = new List<String>();
    final pollScatterData = new List<ScatterPolls>();
    var seriesToReturn = new List<charts.Series<ScatterPolls, DateTime>>();
    final List<String> selectedCandidates = [
      "Biden",
      "Sanders",
      "Warren",
      "Harris",
      "Buttigieg",
      "O'Rourke",
      "Booker"
    ];
    var firstLine = 0;

    HttpClient client = new HttpClient();
    return await client
        .getUrl(Uri.parse(
            "https://projects.fivethirtyeight.com/polls-page/president_primary_polls.csv"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response
          .transform(utf8.decoder) // Decode bytes to UTF-8.
          .transform(new LineSplitter()) // Convert stream to individual lines.
          .listen((String line) {
        if (firstLine == 0)
          firstLine = 1;
        else {
          // Process results.
          //print(line);
          line = line.replaceAll(", ", " ");
          line = line.replaceAll(",PARTY_ID", "PARTY_ID");
          line = line.replaceAll("52,143", "52 143");
          //print(line);

          List row = line.split(','); // split by comma

          int questionId = int.parse(row[0]);
          String state = row[3];
          String pollster = row[5];
          int sampleSize = int.parse(row[12]);
          List dateParts = row[17].split('/');
          DateTime startDate = new DateTime.utc(2000 + int.parse(dateParts[2]),
              int.parse(dateParts[0]), int.parse(dateParts[1]));
          dateParts = row[18].split('/');
          DateTime endDate = new DateTime.utc(2000 + int.parse(dateParts[2]),
              int.parse(dateParts[0]), int.parse(dateParts[1]));
          String party = row[28];
          String answer = row[29];
          double pct = double.parse(row[31]);
          
          //print(questionId);
          //print(state);
          //print(pollster);
          //print(sampleSize);
          //print(startDate);
          //print(endDate);
          //print(party);
          //print(answer);
          //print(pct);

          polls.add(new PollDatum(questionId, state, pollster, sampleSize,
              startDate, endDate, party, answer, pct));

          pollScatterData.add(new ScatterPolls(startDate, pct, answer));
        }
      }, onDone: () {
        print('File is now closed.');

    print(pollScatterData.length);

    selectedCandidates.forEach((candidate) =>
        seriesToReturn.add(new charts.Series<ScatterPolls, DateTime>(
          id: candidate.substring(0, 1),
          domainFn: (ScatterPolls polls, _) => polls.pollDate,
          measureFn: (ScatterPolls polls, _) => polls.result,
          data: pollScatterData
              .where((poll) => poll.answer == candidate)
              .toList(),
        )));

    selectedCandidates.forEach((candidate) { 
      print(candidate);
      print(pollScatterData
          .where((poll) => poll.answer == candidate)
          .toList()
          .length);
    
    return seriesToReturn;
    
    });
      }, onError: (e) {
        print(e.toString());
      });
    });
/* 
    seriesToReturn.add(new charts.Series<ScatterPolls, DateTime>(
        id: 'Biden Polls',
        domainFn: (ScatterPolls polls, _) => polls.pollDate,
        measureFn: (ScatterPolls polls, _) => polls.result,
        data: pollScatterData,
      )); */
/* 
    var pollLineData = [
      new ScatterPolls(new DateTime.utc(2018, 11, 9), 5, "Biden"),
      new ScatterPolls(new DateTime.utc(2019, 2, 20), 15, "Biden"),
      new ScatterPolls(new DateTime.utc(2019, 5, 10), 240, "Biden"),
    ];

    seriesToReturn.add(new charts.Series<ScatterPolls, DateTime>(
        id: 'B2',
        domainFn: (ScatterPolls polls, _) => polls.pollDate,
        measureFn: (ScatterPolls polls, _) => polls.result,
        data: pollLineData)
      // Configure our custom line renderer for this series.
      ..setAttribute(charts.rendererIdKey, 'customLine')); */
  }

/// Sample linear data type.
class ScatterPolls {
  final DateTime pollDate;
  final double result;
  final String answer;

  ScatterPolls(this.pollDate, this.result, this.answer);
}

/// Sample linear data type.
class PollDatum {
  final int questionId;
  final String state;
  final String pollster;
  final int sampleSize;
  final DateTime startDate;
  final DateTime endDate;
  final String party;
  final String answer;
  final double pct;

  PollDatum(this.questionId, this.state, this.pollster, this.sampleSize,
      this.startDate, this.endDate, this.party, this.answer, this.pct);
}

void main() => runApp(ElectionsApp());

class ElectionsApp extends StatefulWidget {
    @override
    State createState() => new ElectionsAppState();
}

class ElectionsAppState extends State<ElectionsApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '2020 Primary Polls',
        home: Scaffold(
          appBar: AppBar(
            title: Text('2020 Primary Polls'),
          ),
          body: new ScatterPlotComboLineChart(),
        ));
  }
}
