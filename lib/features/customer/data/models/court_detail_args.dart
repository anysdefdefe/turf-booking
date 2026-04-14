import 'court_model.dart';

class CourtDetailArgs {
  final Court selectedCourt;
  final List<Court> stadiumCourts;

  const CourtDetailArgs({
    required this.selectedCourt,
    required this.stadiumCourts,
  });
}
