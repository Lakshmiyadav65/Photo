// Mock moments for the frontend build — replaced by a Firestore stream in
// Phase 4 (momentsProvider). Indian-context names per the UI/UX brief.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/moment.dart';

final mockMoments = <Moment>[
  Moment(
    id: 'gang5k',
    title: "Aarav's birthday",
    code: 'GANG5K',
    state: RollState.live,
    photoCount: 14,
    memberCount: 8,
    shotsLeft: 3,
    endsAt: DateTime.now().add(const Duration(hours: 2, minutes: 14)),
    members: ['Aarav', 'Meera', 'Rohan', 'Sana', 'Karan', 'Priya', 'Dev', 'Isha'],
  ),
  Moment(
    id: 'goa204',
    title: 'Goa weekend',
    code: 'GOA204',
    state: RollState.developing,
    photoCount: 32,
    memberCount: 6,
    endsAt: DateTime.now().add(const Duration(minutes: 12, seconds: 42)),
    members: ['Priya', 'Aarav', 'Karan', 'Meera', 'Rohan', 'Dev'],
  ),
  Moment(
    id: 'satn8t',
    title: 'Saturday night out',
    code: 'SATN8T',
    state: RollState.developed,
    photoCount: 27,
    memberCount: 5,
    viewCount: 142,
    developedAt: DateTime.now().subtract(const Duration(days: 3)),
    members: ['Rohan', 'Ananya', 'Karan', 'Meera', 'Dev'],
  ),
  Moment(
    id: 'hyd909',
    title: 'Hyderabad rooftop',
    code: 'HYD909',
    state: RollState.developed,
    photoCount: 19,
    memberCount: 4,
    viewCount: 88,
    developedAt: DateTime.now().subtract(const Duration(days: 7)),
    members: ['Ananya', 'Karan', 'Priya', 'Aarav'],
  ),
];

/// Frontend stand-in for the real-time `momentsProvider` (Phase 4).
final momentsProvider = Provider<List<Moment>>((ref) => mockMoments);

Moment? mockMomentByCode(String code) {
  for (final m in mockMoments) {
    if (m.code.toLowerCase() == code.toLowerCase() ||
        m.id.toLowerCase() == code.toLowerCase()) {
      return m;
    }
  }
  return null;
}
