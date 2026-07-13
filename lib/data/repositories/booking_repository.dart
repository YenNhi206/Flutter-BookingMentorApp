import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/booking.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Backed by `/bookings` (JWT-scoped to "my bookings") - [studentId] is
  /// vestigial, kept only for call-site signature compatibility.
  Future<List<Booking>> getForStudent(String studentId) async {
    final result = await _apiClient.get('/bookings') as Map<String, dynamic>;
    final bookings = result['bookings'] as List<dynamic>;
    return bookings.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
  }

  /// Backed by `/bookings/mentor/list` (JWT-scoped to the calling mentor) -
  /// [mentorId] is vestigial, kept only for call-site signature compatibility.
  Future<List<Booking>> getForMentor(String mentorId) async {
    final result = await _apiClient.get('/bookings/mentor/list') as Map<String, dynamic>;
    final bookings = result['bookings'] as List<dynamic>;
    return bookings.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<List<Booking>> getAll() async {
    final result = await _apiClient.get('/admin/bookings') as Map<String, dynamic>;
    final bookings = result['bookings'] as List<dynamic>;
    return bookings.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
  }

  /// Price is computed server-side from the mentor's rate, so this takes
  /// raw booking params (not a pre-built [Booking]) and returns the
  /// authoritative server copy (server id/price/status).
  Future<Booking> create({
    required String mentorId,
    required DateTime sessionDate,
    required String timeSlot,
    required int durationMinutes,
    String notes = '',
  }) async {
    final result = await _apiClient.post('/bookings', body: {
      'mentorId': mentorId,
      'date': formatBookingDate(sessionDate),
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      if (notes.isNotEmpty) 'notes': notes,
    }) as Map<String, dynamic>;
    return Booking.fromJson(result['booking'] as Map<String, dynamic>);
  }

  /// Maps onto several distinct backend endpoints depending on the target
  /// status and who's acting - [asMentor] disambiguates cancellation, since
  /// student-initiated and mentor-initiated cancels are different endpoints.
  Future<void> updateStatus(String bookingId, BookingStatus status, {bool asMentor = false}) async {
    switch (status) {
      case BookingStatus.confirmed:
        await _apiClient.patch('/bookings/$bookingId/confirm');
        break;
      case BookingStatus.completed:
        await _apiClient.patch('/bookings/$bookingId/complete');
        break;
      case BookingStatus.cancelled:
        if (asMentor) {
          await _apiClient.patch('/bookings/mentor/$bookingId/cancel');
        } else {
          await _apiClient.delete('/bookings/$bookingId');
        }
        break;
      default:
        throw ApiException('Unsupported booking status transition: ${status.name}');
    }
  }
}
