// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// class GoogleResData {
//   String? id;
//   String? email;
//   String? name;
//   String? picture;
//   GoogleResData({
//     this.id,
//     this.email,
//     this.name,
//     this.picture,
//   });

//   GoogleResData copyWith({
//     String? id,
//     String? email,
//     String? name,
//     String? picture,
//   }) {
//     return GoogleResData(
//       id: id ?? this.id,
//       email: email ?? this.email,
//       name: name ?? this.name,
//       picture: picture ?? this.picture,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'id': id,
//       'email': email,
//       'name': name,
//       'picture': picture,
//     };
//   }

//   factory GoogleResData.fromMap(Map<String, dynamic> map) {
//     return GoogleResData(
//       id: map['id'] != null ? map['id'] as String : null,
//       email: map['email'] != null ? map['email'] as String : null,
//       name: map['name'] != null ? map['name'] as String : null,
//       picture: map['picture'] != null ? map['picture'] as String : null,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory GoogleResData.fromJson(String source) => GoogleResData.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() {
//     return 'GoogleResData(id: $id, email: $email, name: $name, picture: $picture)';
//   }

//   @override
//   bool operator ==(covariant GoogleResData other) {
//     if (identical(this, other)) return true;

//     return other.id == id && other.email == email && other.name == name && other.picture == picture;
//   }

//   @override
//   int get hashCode {
//     return id.hashCode ^ email.hashCode ^ name.hashCode ^ picture.hashCode;
//   }
// }
