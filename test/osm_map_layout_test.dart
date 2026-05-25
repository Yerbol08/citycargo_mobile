import 'package:citycargo_mobile/shared/widgets/osm_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('OsmMap has bounded constraints inside Column Expanded',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(height: 80),
              Expanded(
                child: OsmMap(
                  initialCenter: LatLng(51.1605, 71.4704),
                  initialZoom: 12,
                  selectedPoint: LatLng(51.1605, 71.4704),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(errors, isEmpty);
    expect(find.byType(OsmMap), findsOneWidget);
  });

  testWidgets('OsmMap has bounded constraints as standalone Scaffold body',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: OsmMap(
              initialCenter: LatLng(51.1605, 71.4704),
              initialZoom: 12,
              selectedPoint: LatLng(51.1605, 71.4704),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(errors, isEmpty);
    expect(find.byType(OsmMap), findsOneWidget);
  });
}
