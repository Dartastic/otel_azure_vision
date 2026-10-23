// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_azure_vision_suppression.dart';

const _tracerName = 'dartastic_otel_libs_azure_vision';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class AzureVisionResult {
  /// Creates a result.
  const AzureVisionResult({
    this.tagCount,
    this.objectCount,
    this.peopleCount,
    this.readLineCount,
    this.readWordCount,
    this.adultClassification,
    this.captionConfidence,
    this.smartCropAspectRatios,
  });

  final int? tagCount;
  final int? objectCount;
  final int? peopleCount;
  final int? readLineCount;
  final int? readWordCount;

  /// `isAdultContent` / `isGoryContent` / `isRacyContent` from
  /// adult-classification feature. Comma-separated string of any
  /// positives (`adult,racy`) or null/empty if clean.
  final String? adultClassification;

  /// Caption confidence (0..1) from Image Analysis 4.0 caption.
  final double? captionConfidence;

  /// Comma-separated aspect ratios returned by smartCrops.
  final String? smartCropAspectRatios;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class AzureVisionCallResult<T> {
  /// Creates a call result.
  const AzureVisionCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final AzureVisionResult? result;
}

/// Wraps an Azure Image Analysis 4.0 / Read OCR call in a CLIENT span.
/// [features] is the comma-joined list of requested Image Analysis
/// features (e.g. `tags,objects,read,smartCrops,caption,people`).
Future<T> tracedAzureVision<T>({
  required String operation,
  required Future<AzureVisionCallResult<T>> Function() invoke,
  String? features,
  String? region,
  String? modelVersion,
}) async {
  if (azureVisionInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'azure-api',
    'rpc.service': 'Vision',
    'rpc.method': operation,
  };
  if (features != null) m['azure.vision.features'] = features;
  if (region != null) m['cloud.region'] = region;
  if (modelVersion != null) m['azure.vision.model_version'] = modelVersion;

  final span = _tracer().startSpan(
    'vision $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.tagCount != null) {
        extras.add(OTelAPI.attributeInt(
          'azure.vision.tag_count',
          r.result!.tagCount!,
        ));
      }
      if (r.result!.objectCount != null) {
        extras.add(OTelAPI.attributeInt(
          'azure.vision.object_count',
          r.result!.objectCount!,
        ));
      }
      if (r.result!.peopleCount != null) {
        extras.add(OTelAPI.attributeInt(
          'azure.vision.people_count',
          r.result!.peopleCount!,
        ));
      }
      if (r.result!.readLineCount != null) {
        extras.add(OTelAPI.attributeInt(
          'azure.vision.read.line_count',
          r.result!.readLineCount!,
        ));
      }
      if (r.result!.readWordCount != null) {
        extras.add(OTelAPI.attributeInt(
          'azure.vision.read.word_count',
          r.result!.readWordCount!,
        ));
      }
      if (r.result!.adultClassification != null) {
        extras.add(OTelAPI.attributeString(
          'azure.vision.adult_classification',
          r.result!.adultClassification!,
        ));
      }
      if (r.result!.captionConfidence != null) {
        extras.add(OTelAPI.attributeDouble(
          'azure.vision.caption.confidence',
          r.result!.captionConfidence!,
        ));
      }
      if (r.result!.smartCropAspectRatios != null) {
        extras.add(OTelAPI.attributeString(
          'azure.vision.smart_crops.aspect_ratios',
          r.result!.smartCropAspectRatios!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
