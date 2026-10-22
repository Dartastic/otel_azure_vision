// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_azure_vision/otel_azure_vision.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_azure_vision-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('analyze records features + per-feature counts', () async {
    await tracedAzureVision<String>(
      operation: 'analyze',
      features: 'tags,objects,read,caption,people',
      modelVersion: '2023-10-01',
      region: 'eastus',
      invoke: () async => const AzureVisionCallResult(
        value: 'ok',
        result: AzureVisionResult(
          tagCount: 14,
          objectCount: 5,
          peopleCount: 2,
          readLineCount: 12,
          readWordCount: 84,
          captionConfidence: 0.91,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('vision analyze')!);
    expect(a['rpc.service'], 'Vision');
    expect(a['azure.vision.features'], 'tags,objects,read,caption,people');
    expect(a['azure.vision.tag_count'], 14);
    expect(a['azure.vision.caption.confidence'], 0.91);
    expect(a['azure.vision.read.word_count'], 84);
  });

  test('suppression skips spans', () async {
    await runWithoutAzureVisionInstrumentationAsync(() async {
      await tracedAzureVision<String>(
        operation: 'analyze',
        invoke: () async => const AzureVisionCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('vision '), isEmpty);
  });
}
