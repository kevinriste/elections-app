import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class ScatterPlotComboLineChart extends StatefulWidget {
    @override
    State createState() => ScatterPlotComboLineChartState();
}

class ScatterPlotComboLineChartState extends State<ScatterPlotComboLineChart> {
  bool animate = true;
  Future<CustomData> _seriesList = getPollData();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _seriesList,
    builder: (BuildContext context,
              AsyncSnapshot<CustomData> feedState) {
      if (feedState.error != null) {
        print(feedState.error);
      }
      if (feedState.data == null) {
        return Center(child: CircularProgressIndicator());
      }
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: charts.TimeSeriesChart(feedState.data.seriesData,
        animate: animate,
        behaviors: [charts.SeriesLegend(
          // Positions for "start" and "end" will be left and right respectively
          // for widgets with a build context that has directionality ltr.
          // For rtl, "start" and "end" will be right and left respectively.
          // Since this example has directionality of ltr, the legend is
          // positioned on the right side of the chart.
          //position: charts.BehaviorPosition.start,
          // For a legend that is positioned on the left or right of the chart,
          // setting the justification for [endDrawArea] is aligned to the
          // bottom of the chart draw area.
          //outsideJustification: charts.OutsideJustification.startDrawArea,
          // For a legend that is positioned on the left or right of the chart,
          // setting the justification for [endDrawArea] is aligned to the
          // bottom of the chart draw area.
          //insideJustification: charts.InsideJustification.topEnd,
          // By default, if the position of the chart is on the left or right of
          // the chart, [horizontalFirst] is set to false. This means that the
          // legend entries will grow as rows first instead of a column.
          //horizontalFirst: false,
          // By setting this value to 2, the legend entries will grow up to two
          // rows before adding a column.
          desiredMaxColumns: 2,
          // This defines the padding around each legend entry.
          //cellPadding: EdgeInsets.only(right: 4.0, bottom: 4.0),
          // Render the legend entry text with custom styles.
          entryTextStyle: charts.TextStyleSpec(
              //color: charts.Color(r: 127, g: 63, b: 191),
              fontFamily: 'Arial',
              fontSize: 14),
        )],
        // Configure the default renderer as a point renderer. This will be used
        // for any series that does not define a rendererIdKey.
        //
        // This is the default configuration, but is shown here for
        // illustration.
        defaultRenderer: charts.PointRendererConfig(),
        // Custom renderer configuration for the line series.
        customSeriesRenderers: [
          charts.LineRendererConfig(
              // ID used to link series to this renderer.
              customRendererId: 'customLine',
              // Configure the regression line to be painted above the points.
              //
              // By default, series drawn by the point renderer are painted on
              // top of those drawn by a line renderer.
              layoutPaintOrder: charts.LayoutViewPaintOrder.point + 1)
        ],
        primaryMeasureAxis: charts.PercentAxisSpec(
            tickProviderSpec:
                charts.StaticNumericTickProviderSpec([
                 charts.TickSpec(0.0)
                ,charts.TickSpec(0.1)
                ,charts.TickSpec(0.2)
                ,charts.TickSpec(0.3)
                ,charts.TickSpec(0.4)
                ,charts.TickSpec(0.5)
                ,charts.TickSpec(0.6)
                ,charts.TickSpec(0.7)
                ,charts.TickSpec(0.8)
                ,charts.TickSpec(0.9)
                ,charts.TickSpec(1.0)
                ]),
          viewport: charts.NumericExtents(0.0, feedState.data.topPct)
        ))
    );
  });
}
}

Future<CustomData> getPollData() async {
    var polls = List<PollDatum>();
    var pollsterRatings = List<PollsterRating>();
    final pollScatterData = List<ScatterPolls>();
    var seriesToReturn = List<charts.Series<ScatterPolls, DateTime>>();
    var firstLine = 0;

    HttpClient client = HttpClient();

    await client
        .getUrl(Uri.parse(
            "https://raw.githubusercontent.com/fivethirtyeight/data/master/pollster-ratings/pollster-ratings.csv"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) async {
      var lines = response
          .transform(utf8.decoder) // Decode bytes to UTF-8.
          .transform(LineSplitter()); // Convert stream to individual lines.
      await for(String line in lines) {
        if (firstLine == 0)
          firstLine = 1;
        else {
          // Process results.
          line = line.replaceAll(RegExp(r'(?!(([^"]*"){2})*[^"]*$),'), '');

          List row = line.split(','); // split by comma

          String pollster = row[0];
          double plusMinus = double.parse(row[7]);

          pollsterRatings.add(PollsterRating(pollster, plusMinus));
        }
      }
      
      print('File 1 is now closed.');
    });

    firstLine = 0;

    await client
        .getUrl(Uri.parse(
            "https://projects.fivethirtyeight.com/polls-page/president_primary_polls.csv"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) async {
      var lines = response
          .transform(utf8.decoder) // Decode bytes to UTF-8.
          .transform(LineSplitter()); // Convert stream to individual lines.
      await for(String line in lines) {
        if (firstLine == 0)
          firstLine = 1;
        else {
          // Process results.
          line = line.replaceAll(RegExp(r'(?!(([^"]*"){2})*[^"]*$),'), '');

          List row = line.split(','); // split by comma

          int questionId = int.parse(row[0]);
          String state = row[3];
          String pollster = row[5];
          int sampleSize = int.parse(row[12]);
          List dateParts = row[17].split('/');
          DateTime startDate = DateTime.utc(2000 + int.parse(dateParts[2]),
              int.parse(dateParts[0]), int.parse(dateParts[1]));
          dateParts = row[18].split('/');
          DateTime endDate = DateTime.utc(2000 + int.parse(dateParts[2]),
              int.parse(dateParts[0]), int.parse(dateParts[1]));
          String party = row[28];
          String answer = row[29];
          double pct = double.parse(row[31])/100;
          String notes = row[25];

          polls.add(PollDatum(questionId, state, pollster, sampleSize,
              startDate, endDate, party, answer, notes, pct));
        }
      }
      
      print('File 2 is now closed.');
    });

    final bidenPolls = polls
      .where((poll) => poll.answer == 'Biden')
      .map((poll) => poll.questionId)
      .toList()
      .toSet()
      .toList();

    polls = polls
      .where((poll) => poll.party == 'DEM'
                    && poll.notes != "open-ended question"
                    && poll.notes != "head-to-head poll"
                    && bidenPolls.contains(poll.questionId))
      .toList();

    polls.forEach((poll) => pollScatterData.add(ScatterPolls(poll.startDate, poll.pct, poll.answer)));

    final List<String> selectedCandidates = polls.map((poll) => poll.answer)
                            .toList()
                            .toSet()
                            .take(6)
                            .toList();

    for (String candidate in selectedCandidates) {
      seriesToReturn.add(charts.Series<ScatterPolls, DateTime>(
        id: candidate,
        domainFn: (ScatterPolls polls, _) => polls.pollDate,
        measureFn: (ScatterPolls polls, _) => polls.result,
        data: pollScatterData
            .where((poll) => poll.answer == candidate)
            .toList(),
      ));
    }

    double biggestPct = (pollScatterData
    .where((poll) => selectedCandidates.contains(poll.answer))
    .map((poll) => poll.result)
    .reduce(max)
    * 10)
    .ceilToDouble()
    /10;

    print(biggestPct);
    
    return CustomData(biggestPct+.01, seriesToReturn);
  }

class ScatterPolls {
  final DateTime pollDate;
  final double result;
  final String answer;

  ScatterPolls(this.pollDate, this.result, this.answer);
}

class CustomData {
  final double topPct;
  final List<charts.Series<ScatterPolls, DateTime>> seriesData;

  CustomData(this.topPct, this.seriesData);
}

class PollDatum {
  final int questionId;
  final String state;
  final String pollster;
  final int sampleSize;
  final DateTime startDate;
  final DateTime endDate;
  final String party;
  final String answer;
  final String notes;
  final double pct;

  PollDatum(this.questionId, this.state, this.pollster, this.sampleSize,
      this.startDate, this.endDate, this.party, this.answer, this.notes, this.pct);
}

class PollsterRating {
  final String pollster;
  final double plusMinus;

  PollsterRating(this.pollster, this.plusMinus);
}

void main() => runApp(MaterialApp(
        title: '2020 Primary Polls',
        home: ElectionsApp1()));

class ElectionsApp1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: Text('2020 Primary Polls 1'),
          ),
          body: Column(
            children: [
                Align(
      alignment: Alignment.topRight,
        child: RaisedButton(
          child: Text('Settings'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ElectionsApp2()),
            );
          },
        ),)
              ,
                Expanded(
                child: Center(
            child: ScatterPlotComboLineChart()
          ))
            ]
          )
        );
  }
}

class ElectionsApp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: Text('2020 Primary Polls 2'),
          ),
          body: Container(
            child: Center( 
              child: Column(
                children: [
                  ScatterPlotComboLineChart()
                ]
              )
            )
          ),
        );
  }
}
