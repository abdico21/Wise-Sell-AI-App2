import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.businessType,
    required this.phone,
    required this.city,
    required this.country,
  });

  final String businessName;
  final String ownerName;
  final String businessType;
  final String phone;
  final String city;
  final String country;

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'businessType': businessType,
        'phone': phone,
        'city': city,
        'country': country,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      businessName: map['businessName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      businessType: map['businessType'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: map['country'] as String? ?? 'Ethiopia',
    );
  }
}

class BusinessProfileService {
  BusinessProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _firestore.collection('business_profiles').doc(uid);

  Stream<BusinessProfile?> watchMyProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _profileRef(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : BusinessProfile.fromMap(data);
    });
  }

  Future<void> saveMyProfile(BusinessProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before saving a business profile.');
    await _profileRef(user.uid).set({
      ...profile.toMap(),
      'uid': user.uid,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
