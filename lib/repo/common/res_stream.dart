// ignore: constant_identifier_names
enum Status { LOADING, COMPLETED, ERROR }

class ResStream<T> {
  Status? status;
  String? message;
  T? data;

  ResStream.loading() : status = Status.LOADING;
  ResStream.completed(this.data, {this.message}) : status = Status.COMPLETED;
  ResStream.error(this.message) : status = Status.ERROR;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}
