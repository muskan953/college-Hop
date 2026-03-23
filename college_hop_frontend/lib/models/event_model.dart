import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String name;
  final String category;
  final String venue;
  final String organizer;
  final DateTime startDate;
  final DateTime? endDate;
  final String timeDescription;
  final String eventLink;
  final String brochureUrl;
  final String ticketLink;
  final String status;
  final DateTime createdAt;
  final int attendees;

  EventModel({
    required this.id,
    required this.name,
    required this.category,
    required this.venue,
    required this.organizer,
    required this.startDate,
    this.endDate,
    this.timeDescription = '',
    this.eventLink = '',
    this.brochureUrl = '',
    this.ticketLink = '',
    required this.status,
    required this.createdAt,
    this.attendees = 0,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      organizer: json['organizer'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      timeDescription: json['time_description'] as String? ?? '',
      eventLink: json['event_link'] as String? ?? '',
      brochureUrl: json['brochure_url'] as String? ?? '',
      ticketLink: json['ticket_link'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      attendees: (json['attendees'] as int?) ?? 0,
    );
  }

  // ── Helpers for UI display ───────────────────────────────────────────────

  /// 3-letter uppercase month abbreviation, e.g. "MAR"
  String get monthAbbr => DateFormat('MMM').format(startDate).toUpperCase();

  /// Zero-padded day, e.g. "08"
  String get dayStr => DateFormat('dd').format(startDate);

  /// Full "Month YYYY" string for grouping, e.g. "March 2026"
  String get groupKey => DateFormat('MMMM yyyy').format(startDate);

  /// Relative time label, e.g. "12 days"
  String get daysLeft {
    final diff = startDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Past';
    if (diff == 0) return 'Today';
    return '$diff days';
  }
}
