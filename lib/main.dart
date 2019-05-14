/// Example of a combo scatter plot chart with a second series rendered as a
/// line.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class ScatterPlotComboLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  ScatterPlotComboLineChart(this.seriesList, {this.animate});

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory ScatterPlotComboLineChart.withSampleData() {
    return new ScatterPlotComboLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(seriesList,
        animate: animate,
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
  static List<charts.Series<ScatterPolls, DateTime>> _createSampleData() {
    final desktopSalesData = [
      new ScatterPolls(new DateTime.utc(1989, 11, 9), 5),
      new ScatterPolls(new DateTime.utc(1989, 12, 9), 25),
      new ScatterPolls(new DateTime.utc(1990, 1, 9), 75),
      new ScatterPolls(new DateTime.utc(1990, 2, 9), 225),
      new ScatterPolls(new DateTime.utc(1990, 3, 9), 50),
      new ScatterPolls(new DateTime.utc(1990, 4, 9), 75),
      new ScatterPolls(new DateTime.utc(1990, 5, 9), 100),
      new ScatterPolls(new DateTime.utc(1990, 6, 9), 150),
      new ScatterPolls(new DateTime.utc(1990, 7, 9), 10),
      new ScatterPolls(new DateTime.utc(1990, 8, 9), 300),
      new ScatterPolls(new DateTime.utc(1990, 9, 9), 15),
      new ScatterPolls(new DateTime.utc(1990, 10, 9), 200),
    ];

    var myRegressionData = [
      new ScatterPolls(new DateTime.utc(1989, 11, 9), 5),
      new ScatterPolls(new DateTime.utc(1990, 2, 20), 15),
      new ScatterPolls(new DateTime.utc(1990, 10, 9), 240),
    ];

    final maxMeasure = 300;

    return [
      new charts.Series<ScatterPolls, DateTime>(
        id: 'Sales',
        // Providing a color function is optional.
        colorFn: (ScatterPolls sales, _) {
          // Bucket the measure column value into 3 distinct colors.
          final bucket = sales.result / maxMeasure;

          if (bucket < 1 / 3) {
            return charts.MaterialPalette.blue.shadeDefault;
          } else if (bucket < 2 / 3) {
            return charts.MaterialPalette.red.shadeDefault;
          } else {
            return charts.MaterialPalette.green.shadeDefault;
          }
        },
        domainFn: (ScatterPolls sales, _) => sales.pollDate,
        measureFn: (ScatterPolls sales, _) => sales.result,
        data: desktopSalesData,
      ),
      new charts.Series<ScatterPolls, DateTime>(
          id: 'Mobile',
          colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
          domainFn: (ScatterPolls sales, _) => sales.pollDate,
          measureFn: (ScatterPolls sales, _) => sales.result,
          data: myRegressionData)
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }
}

/// Sample linear data type.
class ScatterPolls {
  final DateTime pollDate;
  final double result;

  ScatterPolls(this.pollDate, this.result);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2020 Primary Polls',
      home: Scaffold(
      appBar: AppBar(
        title: Text('2020 Primary Polls'),
      ),
      body: new ScatterPlotComboLineChart.withSampleData(),
    )
    );
  }
}
