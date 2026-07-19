import 'package:akm_finance_manager/services/preferences/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedYearNotifier extends StateNotifier<int?> {
  SelectedYearNotifier(this._preferences) : super(DateTime.now().year) {
    _load();
  }

  final PreferencesService _preferences;

  Future<void> _load() async {
    final savedYear = await _preferences.getSelectedYear();
    if (await _preferences.isAllYearsSelected()) {
      state = null;
    } else if (savedYear != null) {
      state = savedYear;
    }
  }

  Future<void> selectYear(int? year) async {
    state = year;
    await _preferences.setSelectedYear(year);
  }
}

final selectedYearProvider = StateNotifierProvider<SelectedYearNotifier, int?>(
  (ref) => SelectedYearNotifier(PreferencesService.instance),
);
