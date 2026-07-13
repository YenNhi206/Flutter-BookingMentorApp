import '../../core/api_client.dart';
import '../../models/review.dart';

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Review>> getForMentor(String mentorId) async {
    final result = await _apiClient.get(
      '/reviews',
      query: {'targetType': 'mentor', 'targetId': mentorId},
      auth: false,
    ) as Map<String, dynamic>;
    final reviews = result['reviews'] as List<dynamic>;
    return reviews.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// The backend recomputes the mentor's aggregate rating itself - the
  /// caller (`MentorProvider.submitReview`) already reloads mentors
  /// afterward, which is enough to pick up the change.
  Future<void> create(Review review) async {
    await _apiClient.post('/reviews', body: {
      'targetType': 'mentor',
      'targetId': review.mentorId,
      'rating': review.rating,
      'comment': review.comment,
    });
  }
}
