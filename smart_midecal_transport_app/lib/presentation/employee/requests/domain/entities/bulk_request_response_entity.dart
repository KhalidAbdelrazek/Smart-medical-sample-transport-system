// ============================================================
// Bulk Request Response – Domain Entities
// ============================================================
// API response shape:
// {
//   "success": true | false,
//   "message": "...",
//   "data": {
//     "successful": [ { "sample_code": "PT-0001", "request_id": "..." } ],
//     "failed":     [ { "sample_code": "PT-0002", "error": ["Already requested"] } ],
//     "summary":    { "total": 2, "successful": 1, "failed": 1 }
//   },
//   "errors": null | { "detail": "Given token not valid ...", "code": "token_not_valid" }
// }
// ============================================================

class BulkRequestResponseEntity {
  final bool? success;
  final String? message;
  final BulkRequestDataEntity? data;
  final dynamic errors;

  const BulkRequestResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  /// Returns true when the errors object indicates an expired / invalid token.
  bool get isTokenExpired {
    if (errors == null) return false;
    if (errors is Map) {
      final code = errors['code'];
      return code == 'token_not_valid';
    }
    return false;
  }
}

// -------------------------------------------------------

class BulkRequestDataEntity {
  final List<BulkSampleSuccessEntity> successful;
  final List<BulkSampleFailedEntity> failed;
  final BulkSummaryEntity? summary;

  const BulkRequestDataEntity({
    this.successful = const [],
    this.failed = const [],
    this.summary,
  });
}

// -------------------------------------------------------

class BulkSampleSuccessEntity {
  final String? sampleCode;
  final String? requestId;

  const BulkSampleSuccessEntity({this.sampleCode, this.requestId});
}

// -------------------------------------------------------

class BulkSampleFailedEntity {
  final String? sampleCode;
  final List<String> error;

  const BulkSampleFailedEntity({
    this.sampleCode,
    this.error = const [],
  });

  /// Convenience getter — joins error messages into one readable string.
  String get errorMessage => error.join(', ');
}

// -------------------------------------------------------

class BulkSummaryEntity {
  final int total;
  final int successful;
  final int failed;

  const BulkSummaryEntity({
    this.total = 0,
    this.successful = 0,
    this.failed = 0,
  });
}
