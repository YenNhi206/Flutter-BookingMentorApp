import 'package:flutter/foundation.dart';

import '../data/repositories/mentor_repository.dart';
import '../data/repositories/review_repository.dart';
import '../models/mentor.dart';
import '../models/review.dart';

class MentorProvider extends ChangeNotifier {
  final MentorRepository _repository;
  final ReviewRepository _reviewRepository;

  MentorProvider({MentorRepository? repository, ReviewRepository? reviewRepository})
      : _repository = repository ?? MentorRepository(),
        _reviewRepository = reviewRepository ?? ReviewRepository();

  List<Mentor> _mentors = [];
  bool _isLoading = false;
  String _query = '';

  List<Mentor> get mentors => _mentors;
  bool get isLoading => _isLoading;
  String get query => _query;

  Future<void> loadMentors() async {
    _isLoading = true;
    notifyListeners();
    _mentors = await _repository.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _query = query;
    notifyListeners();
    _mentors = query.isEmpty ? await _repository.getAll() : await _repository.search(query);
    notifyListeners();
  }

  Future<Mentor?> getById(String id) => _repository.getById(id);

  Future<List<Review>> getReviews(String mentorId) => _reviewRepository.getForMentor(mentorId);

  Future<void> submitReview(Review review) async {
    await _reviewRepository.create(review);
    await loadMentors();
  }
}
