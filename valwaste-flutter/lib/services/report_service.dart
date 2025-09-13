import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Create report (Resident → Barangay Official)
  static Future<void> createReport({
    required String title,
    required String description,
    required String location,
    required String category,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    
    await _firestore.collection('barangay_reports').add({
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'imageUrl': imageUrl,
      'reportedBy': userData?['name'] ?? 'Anonymous',
      'reporterId': user.uid,
      'status': 'pending_review', // pending_review, sent_to_admin, rejected, resolved, unresolved
      'priority': 'low', // low, medium, high
      'isCritical': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'barangayOfficialId': null,
      'adminNotes': null,
      'barangayNotes': null,
    });
  }
  
  // Get reports for Barangay Official
  static Stream<QuerySnapshot> getBarangayReports() {
    return _firestore
        .collection('barangay_reports')
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Get reports for Admin (sent by Barangay Official)
  static Stream<QuerySnapshot> getAdminReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Get reports for Resident (their own reports)
  static Stream<QuerySnapshot> getResidentReports(String userId) {
    return _firestore
        .collection('barangay_reports')
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Barangay Official actions
  static Future<void> sendReportToAdmin(String reportId, {bool isCritical = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Get the barangay report
    final barangayDoc = await _firestore.collection('barangay_reports').doc(reportId).get();
    final reportData = barangayDoc.data();
    
    if (reportData == null) throw Exception('Report not found');
    
    // Create report in admin collection
    await _firestore.collection('reports').add({
      'title': reportData['title'],
      'description': reportData['description'],
      'location': reportData['location'],
      'category': reportData['category'],
      'imageUrl': reportData['imageUrl'],
      'reportedBy': reportData['reportedBy'],
      'reporterId': reportData['reporterId'],
      'barangayReportId': reportId,
      'barangayOfficialId': user.uid,
      'status': 'pending',
      'priority': isCritical ? 'high' : reportData['priority'],
      'isCritical': isCritical,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update barangay report status
    await _firestore.collection('barangay_reports').doc(reportId).update({
      'status': 'sent_to_admin',
      'barangayOfficialId': user.uid,
      'isCritical': isCritical,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  static Future<void> rejectReport(String reportId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('barangay_reports').doc(reportId).update({
      'status': 'rejected',
      'barangayOfficialId': user.uid,
      'barangayNotes': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Admin actions (these update both collections)
  static Future<void> resolveReport(String reportId) async {
    // Update admin report
    await _firestore.collection('reports').doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Get the linked barangay report and update it
    final reportDoc = await _firestore.collection('reports').doc(reportId).get();
    final barangayReportId = reportDoc.data()?['barangayReportId'];
    
    if (barangayReportId != null) {
      await _firestore.collection('barangay_reports').doc(barangayReportId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  static Future<void> unresolveReport(String reportId) async {
    // Update admin report
    await _firestore.collection('reports').doc(reportId).update({
      'status': 'unresolved',
      'unresolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Get the linked barangay report and update it
    final reportDoc = await _firestore.collection('reports').doc(reportId).get();
    final barangayReportId = reportDoc.data()?['barangayReportId'];
    
    if (barangayReportId != null) {
      await _firestore.collection('barangay_reports').doc(barangayReportId).update({
        'status': 'unresolved',
        'unresolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
