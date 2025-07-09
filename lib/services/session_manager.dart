import 'saved_hand_manager_service.dart';
import 'session_note_service.dart';
import 'training_session_service.dart';

class SessionManager {
  final SavedHandManagerService hands;
  final SessionNoteService notes;
  final TrainingSessionService sessions;

  SessionManager({
    required this.hands,
    required this.notes,
    required this.sessions,
  });

  Future<void> reset(int sessionId) async {
    await hands.removeSession(sessionId);
    await notes.setNote(sessionId, '');
    await sessions.reset();
  }
}
