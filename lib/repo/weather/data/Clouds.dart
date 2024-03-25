// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Clouds {
  int? all;
  Clouds({
    this.all,
  });

  Clouds copyWith({
    int? all,
  }) {
    return Clouds(
      all: all ?? this.all,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'all': all,
    };
  }

  factory Clouds.fromMap(Map<String, dynamic> map) {
    return Clouds(
      all: map['all'] != null ? map['all'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Clouds.fromJson(String source) => Clouds.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Clouds(all: $all)';

  @override
  bool operator ==(covariant Clouds other) {
    if (identical(this, other)) return true;

    return other.all == all;
  }

  @override
  int get hashCode => all.hashCode;
}
