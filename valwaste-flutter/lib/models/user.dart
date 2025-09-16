import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { resident, barangayOfficial, driver, collector, administrator }

class UserModel {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String phone;
  final String address;
  final String barangay;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.barangay,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString();
    final lastName = json['lastName']?.toString();
    return UserModel(
      id: json['id'] ?? '',
      name: _buildName(json),
      firstName: firstName,
      lastName: lastName,
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      barangay: json['barangay'] ?? '',
      role: _parseRole(json['role']),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final firstName = data['firstName']?.toString();
      final lastName = data['lastName']?.toString();
      return UserModel(
        id: doc.id,
        name: _buildName(data),
        firstName: firstName,
        lastName: lastName,
        email: data['email']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        address: data['address']?.toString() ?? '',
        barangay: data['barangay']?.toString() ?? '',
        role: _parseRole(data['role']),
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    } catch (e) {
      print('Error creating UserModel from Firestore: $e');
      print('Raw data: ${doc.data()}');
      rethrow;
    }
  }

  // Build name from firstName and lastName or use name field
  static String _buildName(Map<String, dynamic> data) {
    // Check if firstName and lastName exist
    final firstName = data['firstName']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    // Fallback to name field if it exists
    final name = data['name']?.toString() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    // If no name data, return empty string
    return '';
  }

  // Parse role from string
  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.resident;

    String roleString = roleData.toString().toLowerCase();
    switch (roleString) {
      case 'resident':
        return UserRole.resident;
      case 'barangay official':
      case 'barangayofficial':
        return UserRole.barangayOfficial;
      case 'driver':
        return UserRole.driver;
      case 'collector':
        return UserRole.collector;
      case 'administrator':
      case 'admin':
        return UserRole.administrator;
      default:
        return UserRole.resident;
    }
  }

  // Parse timestamp safely
  static DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) return DateTime.parse(timestamp);
      return DateTime.now();
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }

  // Convert role to string for Firestore
  String get roleString {
    switch (role) {
      case UserRole.resident:
        return 'Resident';
      case UserRole.barangayOfficial:
        return 'Barangay Official';
      case UserRole.driver:
        return 'Driver';
      case UserRole.collector:
        return 'Collector';
      case UserRole.administrator:
        return 'Administrator';
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'barangay': barangay,
      'role': roleString,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'email': email,
      'phone': phone,
      'address': address,
      'barangay': barangay,
      'role': roleString,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Include firstName and lastName if available
    if (firstName != null && firstName!.isNotEmpty) {
      data['firstName'] = firstName;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      data['lastName'] = lastName;
    }
    
    // Only include name field if firstName/lastName are not available
    if ((firstName == null || firstName!.isEmpty) && 
        (lastName == null || lastName!.isEmpty)) {
      data['name'] = name;
    }
    
    return data;
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? barangay,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      barangay: barangay ?? this.barangay,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, address: $address, barangay: $barangay, role: $roleString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.address == address &&
        other.barangay == barangay &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        barangay.hashCode ^
        role.hashCode;
  }
}
