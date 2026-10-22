// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_azure_vision/otel_azure_vision.dart';

/// Traces Azure Image Analysis 4.0 / Read OCR calls with OpenTelemetry.
///
/// `otel_azure_vision` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Azure Image Analysis 4.0 / Read OCR call in
/// [tracedAzureVision]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'azure-vision-example');

  // Wraps an Azure Image Analysis 4.0 / Read OCR call in a CLIENT span.
  final azureVisionId = await tracedAzureVision<String>(
    operation: 'create',
    features: 'example',
    region: 'us-east-1',
    modelVersion: 'standard',
    invoke: () async {
      // Make the Azure Image Analysis 4.0 / Read OCR call here, then report what it returned.
      const id = 'azure_vision_8f3a2c';
      return const AzureVisionCallResult(
          value: id,
          result: AzureVisionResult(
              tagCount: 3,
              objectCount: 3,
              peopleCount: 3,
              readLineCount: 3,
              readWordCount: 3,
              adultClassification: 'isAdultContent',
              captionConfidence: 0.5,
              smartCropAspectRatios: 'example'));
    },
  );
  OTelLog.info('tracedAzureVision create returned $azureVisionId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAzureVisionInstrumentationAsync.
  await runWithoutAzureVisionInstrumentationAsync(
    () => tracedAzureVision<String>(
      operation: 'create',
      features: 'example',
      region: 'us-east-1',
      modelVersion: 'standard',
      invoke: () async {
        const id = 'azure_vision_8f3a2c';
        return const AzureVisionCallResult(
            value: id,
            result: AzureVisionResult(
                tagCount: 3,
                objectCount: 3,
                peopleCount: 3,
                readLineCount: 3,
                readWordCount: 3,
                adultClassification: 'isAdultContent',
                captionConfidence: 0.5,
                smartCropAspectRatios: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
