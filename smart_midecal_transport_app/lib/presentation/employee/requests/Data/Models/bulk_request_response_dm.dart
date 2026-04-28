import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/bulk_request_response_entity.dart';

// ============================================================
// Bulk Request Response – Data Models (fromJson)
// ============================================================

class BulkRequestResponseDm extends BulkRequestResponseEntity {
  const BulkRequestResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory BulkRequestResponseDm.fromJson(Map<String, dynamic> json) {
    return BulkRequestResponseDm(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? BulkRequestDataDm.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }
}

// -------------------------------------------------------

class BulkRequestDataDm extends BulkRequestDataEntity {
  const BulkRequestDataDm({
    super.successful,
    super.failed,
    super.summary,
  });

  factory BulkRequestDataDm.fromJson(Map<String, dynamic> json) {
    List<BulkSampleSuccessEntity> successList = [];
    if (json['successful'] != null) {
      successList = (json['successful'] as List<dynamic>)
          .map((e) =>
              BulkSampleSuccessDm.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<BulkSampleFailedEntity> failedList = [];
    if (json['failed'] != null) {
      failedList = (json['failed'] as List<dynamic>)
          .map((e) =>
              BulkSampleFailedDm.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return BulkRequestDataDm(
      successful: successList,
      failed: failedList,
      summary: json['summary'] != null
          ? BulkSummaryDm.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

// -------------------------------------------------------

class BulkSampleSuccessDm extends BulkSampleSuccessEntity {
  const BulkSampleSuccessDm({super.sampleCode, super.requestId});

  factory BulkSampleSuccessDm.fromJson(Map<String, dynamic> json) {
    return BulkSampleSuccessDm(
      sampleCode: json['sample_code'] as String?,
      requestId: json['request_id'] as String?,
    );
  }
}

// -------------------------------------------------------

class BulkSampleFailedDm extends BulkSampleFailedEntity {
  const BulkSampleFailedDm({super.sampleCode, super.error});

  factory BulkSampleFailedDm.fromJson(Map<String, dynamic> json) {
    List<String> errors = [];
    if (json['error'] != null) {
      errors = (json['error'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    return BulkSampleFailedDm(
      sampleCode: json['sample_code'] as String?,
      error: errors,
    );
  }
}

// -------------------------------------------------------

class BulkSummaryDm extends BulkSummaryEntity {
  const BulkSummaryDm({
    super.total,
    super.successful,
    super.failed,
  });

  factory BulkSummaryDm.fromJson(Map<String, dynamic> json) {
    return BulkSummaryDm(
      total: (json['total'] as int?) ?? 0,
      successful: (json['successful'] as int?) ?? 0,
      failed: (json['failed'] as int?) ?? 0,
    );
  }
}
