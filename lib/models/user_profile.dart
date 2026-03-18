import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final String gender;
  final String region;
  final String profilePicture;
  final int coins;
  final List<dynamic> purchaseHistory;
  final DateTime joinDate;

  UserProfile({
    required this.userId,
    required this.name,
    required this.gender,
    required this.region,
    required this.profilePicture,
    required this.coins,
    required this.purchaseHistory,
    required this.joinDate,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      region: data['region'] ?? '',
      profilePicture: data['profile_picture'] ?? '',
      coins: data['coins'] ?? 0,
      purchaseHistory: data['purchase_history'] ?? [],
      joinDate: (data['join_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'region': region,
      'profile_picture': profilePicture,
      'coins': coins,
      'purchase_history': purchaseHistory,
      'join_date': Timestamp.fromDate(joinDate),
    };
  }
}
