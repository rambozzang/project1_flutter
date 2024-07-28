// Request Data Class
class MidLandFcstRequest {
  final String serviceKey;
  final String regId;
  final String tmFc;
  final String dataType;
  final int numOfRows;
  final int pageNo;

  MidLandFcstRequest({
    required this.serviceKey,
    required this.regId,
    required this.tmFc,
    this.dataType = 'JSON',
    this.numOfRows = 10,
    this.pageNo = 1,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'ServiceKey': serviceKey,
      'regId': regId,
      'tmFc': tmFc,
      'dataType': dataType,
      'numOfRows': numOfRows.toString(),
      'pageNo': pageNo.toString(),
    };
  }
}
