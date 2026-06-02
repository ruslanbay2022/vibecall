import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_history_entry.dart';

part 'call_history_controller.g.dart';

@riverpod
class CallHistoryController extends _$CallHistoryController {
  CallHistoryFilter _currentFilter = CallHistoryFilter.all;

  @override
  Future<List<CallHistoryEntry>> build() async {
    final repo = ref.watch(callRepositoryProvider);
    return repo.fetchCallHistory(filter: _currentFilter);
  }

  Future<void> setFilter(CallHistoryFilter filter) async {
    if (_currentFilter == filter && state.hasValue) return;
    _currentFilter = filter;
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
