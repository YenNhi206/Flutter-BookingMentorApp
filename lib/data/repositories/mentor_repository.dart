import '../../core/api_client.dart';
import '../../models/mentor.dart';

class MentorRepository {
  final ApiClient _apiClient;

  MentorRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Public catalog: only mentors that have been approved by an admin and
  /// are still active show up to students.
  Future<List<Mentor>> getAll() async {
    final result = await _apiClient.get('/mentors', auth: false) as Map<String, dynamic>;
    final mentors = result['mentors'] as List<dynamic>;
    return mentors.map((m) => Mentor.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Mentor?> getById(String id) async {
    try {
      final result = await _apiClient.get('/mentors/$id', auth: false) as Map<String, dynamic>;
      return Mentor.fromJson(result['mentor'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Backed by `/mentors/me` (the currently authenticated mentor's own
  /// profile) - the backend has no "look up mentor profile by arbitrary
  /// user id" endpoint, so [userId] is only meaningful when it's the
  /// current user, which is the only way this is ever called.
  Future<Mentor?> getByUserId(String userId) async {
    try {
      final result = await _apiClient.get('/mentors/me') as Map<String, dynamic>;
      return Mentor.fromDetailJson(result['mentor'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// No server-side search endpoint exists, so this filters the public
  /// catalog client-side - acceptable for a small demo dataset.
  Future<List<Mentor>> search(String query) async {
    final all = await getAll();
    final lower = query.toLowerCase();
    return all
        .where((m) =>
            m.name.toLowerCase().contains(lower) ||
            m.title.toLowerCase().contains(lower) ||
            m.expertise.any((e) => e.toLowerCase().contains(lower)))
        .toList();
  }

  /// Admin-only: every mentor regardless of approval/active state.
  Future<List<Mentor>> getAllForAdmin() async {
    final result = await _apiClient.get('/admin/mentors') as Map<String, dynamic>;
    final mentors = result['mentors'] as List<dynamic>;
    return mentors.map((m) => Mentor.fromDetailJson(m as Map<String, dynamic>)).toList();
  }

  /// Self-serve mentor application (`POST /mentors/apply`) - replaces the
  /// old seed-only `create`/`insertAll` methods.
  Future<void> apply({
    required String title,
    required String bio,
    required List<String> expertise,
    required double hourlyRate,
  }) async {
    await _apiClient.post('/mentors/apply', body: {
      'title': title,
      'bio': bio,
      'skills': expertise,
      'pricePerHour': hourlyRate,
    });
  }

  /// Admin approve/reject. These map to two distinct backend endpoints
  /// (not one generic status-setter): approving also flips `isActive` on,
  /// rejecting requires a reason string the current admin UI doesn't
  /// collect yet, so a placeholder is sent.
  Future<void> updateStatus(String mentorId, MentorStatus status) async {
    if (status == MentorStatus.approved) {
      await _apiClient.patch('/admin/mentors/$mentorId/status', body: {'isActive': true});
    } else {
      await _apiClient.patch(
        '/admin/mentors/$mentorId/reject',
        body: {'reason': 'Rejected by admin'},
      );
    }
  }

  Future<void> updateActive(String mentorId, bool isActive) async {
    await _apiClient.patch('/admin/mentors/$mentorId/status', body: {'isActive': isActive});
  }
}
