import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/safety_service.dart';

// Matching states
enum MatchingState {
  idle,
  searching,
  connecting,
  found,
  failed,
  retrying,
}

/// Carries everything the video-chat screen needs after a successful match.
class MatchResult {
  final String matchedUserId;
  final String channelName;
  final String matchId;

  const MatchResult({
    required this.matchedUserId,
    required this.channelName,
    required this.matchId,
  });
}

/// Firestore-backed matchmaking service.
///
/// Data model
/// ──────────
/// matchmaking_queue/{userId}
///   userId          : string
///   joinedAt        : Timestamp
///   genderPreference: string?   — gender the user wants to be matched with
///   regionPreference: string?   — region the user wants to be matched with
///   myGender        : string?   — the user's own gender
///   myRegion        : string?   — the user's own region
///   isPriority      : bool
///   status          : 'waiting' | 'matched' | 'cancelled'
///   matchId         : string?   — filled when status == 'matched'
///
/// matches/{matchId}
///   user1Id     : string
///   user2Id     : string
///   channelName : string   — used as the Agora channel ID
///   createdAt   : Timestamp
///   status      : 'active' | 'ended'
///
/// Algorithm
/// ─────────
/// 1. Write own queue entry (status='waiting').
/// 2. Listen to own queue entry — completes the pending Future when
///    status becomes 'matched' (either we claimed someone or were claimed).
/// 3. Concurrently query for other waiting users and attempt to claim
///    one via a Firestore transaction (atomic, race-condition safe).
/// 4. cancelMatch() tears down the listener and removes the queue entry.
class MatchingService {
  final SafetyService _safetyService;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  MatchingState _currentState = MatchingState.idle;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  Completer<MatchResult?>? _matchCompleter;
  StreamSubscription<DocumentSnapshot>? _queueListener;
  bool _cancelRequested = false;

  MatchingService(
    this._safetyService, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  MatchingState get currentState => _currentState;

  CollectionReference<Map<String, dynamic>> get _queue =>
      _db.collection('matchmaking_queue');

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');

  // ── Public API ────────────────────────────────────────────────────────────

  /// Enters the matchmaking queue and resolves with a [MatchResult] once a
  /// partner is found, or `null` if the search was cancelled.
  ///
  /// [genderPreference] — gender the local user wants to match with.
  /// [regionPreference] — region the local user wants to match with.
  /// [isPriority]       — whether the user has priority-matching active.
  Future<MatchResult?> findMatch({
    String? genderPreference,
    String? regionPreference,
    bool isPriority = false,
    bool isRetry = false,
  }) async {
    if (!isRetry) {
      _retryCount = 0;
    }

    _cancelRequested = false;
    _currentState = MatchingState.searching;

    // Rate-limit check
    final canSkip = await _safetyService.canSkip();
    if (!canSkip) {
      _currentState = MatchingState.failed;
      throw Exception('Too many skips. Please wait before trying again.');
    }

    final myUid = _auth.currentUser?.uid;
    if (myUid == null) {
      _currentState = MatchingState.failed;
      throw Exception('Not signed in. Please sign in before matching.');
    }

    try {
      _matchCompleter = Completer<MatchResult?>();

      // Look up the current user's profile to populate filter fields that
      // other users query on (myGender, myRegion).
      String? myGender;
      String? myRegion;
      try {
        final profileDoc = await _db.collection('users').doc(myUid).get();
        if (profileDoc.exists) {
          final pd = profileDoc.data()!;
          myGender = pd['gender'] as String?;
          myRegion = pd['region'] as String?;
        }
      } catch (_) {
        // Profile unavailable — proceed without gender/region info.
      }

      // 1. Write own queue entry.
      await _queue.doc(myUid).set({
        'userId': myUid,
        'joinedAt': FieldValue.serverTimestamp(),
        'genderPreference': genderPreference,
        'regionPreference': regionPreference,
        'myGender': myGender,
        'myRegion': myRegion,
        'isPriority': isPriority,
        'status': 'waiting',
        'matchId': null,
      });

      if (_cancelRequested) {
        await _removeFromQueue(myUid);
        _currentState = MatchingState.idle;
        return null;
      }

      // 2. Listen to own queue entry for status == 'matched'.
      _queueListener?.cancel();
      _queueListener = _queue.doc(myUid).snapshots().listen(
        (snap) async {
          if (!snap.exists || _matchCompleter == null || _matchCompleter!.isCompleted) return;
          final data = snap.data();
          if (data == null) return;
          if (data['status'] == 'matched') {
            final matchId = data['matchId'] as String?;
            if (matchId != null) {
              await _resolveMatch(matchId, myUid);
            }
          }
        },
        onError: (Object err) {
          if (!(_matchCompleter?.isCompleted ?? true)) {
            _matchCompleter!.completeError(err);
          }
        },
      );

      // 3. Concurrently try to claim a waiting user.
      _currentState = MatchingState.connecting;
      _tryClaimMatch(myUid, genderPreference: genderPreference, regionPreference: regionPreference);

      // 4. Await either the claim succeeding or being claimed by someone else.
      final result = await _matchCompleter!.future;
      if (result != null) {
        _currentState = MatchingState.found;
      }
      return result;
    } catch (e) {
      _currentState = MatchingState.failed;

      if (_cancelRequested) {
        return null;
      }

      if (_retryCount < _maxRetries) {
        _retryCount++;
        _currentState = MatchingState.retrying;
        final delay = _baseRetryDelay * (1 << (_retryCount - 1));
        await Future.delayed(delay);
        return findMatch(
          genderPreference: genderPreference,
          regionPreference: regionPreference,
          isPriority: isPriority,
          isRetry: true,
        );
      }
      rethrow;
    }
  }

  /// Cancels an in-progress search and removes the user from the queue.
  void cancelMatch() {
    _cancelRequested = true;
    _queueListener?.cancel();
    _queueListener = null;

    final uid = _auth.currentUser?.uid;
    if (uid != null &&
        (_currentState == MatchingState.searching ||
            _currentState == MatchingState.connecting ||
            _currentState == MatchingState.retrying)) {
      _removeFromQueue(uid).catchError((_) {});
    }

    if (!(_matchCompleter?.isCompleted ?? true)) {
      _matchCompleter!.complete(null);
    }

    _currentState = MatchingState.idle;
    _retryCount = 0;
  }

  /// Skips the current search (rate-limited).
  Future<bool> skipMatch() async {
    final canSkip = await _safetyService.canSkip();
    if (!canSkip) return false;

    if (_currentState == MatchingState.searching ||
        _currentState == MatchingState.connecting) {
      cancelMatch();
    }
    return true;
  }

  /// Marks a completed match as ended in Firestore.
  Future<void> endMatch(String matchId) async {
    await _matches.doc(matchId).update({'status': 'ended'}).catchError((_) {});
  }

  void reset() {
    _currentState = MatchingState.idle;
    _retryCount = 0;
  }

  /// Reports and blocks a user, storing the report locally and in Firestore.
  Future<void> reportAndBlockUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
    required String chatSessionId,
  }) async {
    await _safetyService.reportUser(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
      chatSessionId: chatSessionId,
    );

    await _safetyService.blockUser(
      blockerId: reporterId,
      blockedUserId: reportedUserId,
      reason: reason,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Queries for a waiting user and atomically claims them.
  ///
  /// If no candidate is available right now the method returns without
  /// completing the completer — the listener will fire later when someone
  /// else enters the queue and claims us.
  Future<void> _tryClaimMatch(
    String myUid, {
    String? genderPreference,
    String? regionPreference,
  }) async {
    try {
      // Build the query. Firestore does not support `!=` combined with
      // other filters without a composite index, so we exclude ourselves
      // in the client-side loop below.
      Query<Map<String, dynamic>> query = _queue
          .where('status', isEqualTo: 'waiting')
          .orderBy('joinedAt');

      if (genderPreference != null) {
        // Match users whose own gender is what I'm looking for.
        query = query.where('myGender', isEqualTo: genderPreference);
      }
      if (regionPreference != null) {
        query = query.where('myRegion', isEqualTo: regionPreference);
      }

      final snapshot = await query.limit(20).get();

      for (final doc in snapshot.docs) {
        if (_matchCompleter?.isCompleted ?? true) return;
        if (_cancelRequested) return;

        final candidateId = doc.data()['userId'] as String?;
        if (candidateId == null || candidateId == myUid) continue;

        // Skip blocked users.
        if (await _safetyService.isUserBlocked(candidateId)) continue;

        // Atomically claim this candidate.
        final claimed = await _claimCandidate(myUid, candidateId);
        if (claimed) return; // Listener will resolve the completer.
      }
    } catch (_) {
      // Errors here are non-fatal: we keep waiting to be claimed.
    }
  }

  /// Runs a Firestore transaction that pairs [myUid] with [candidateId].
  ///
  /// Returns `true` if the claim succeeded, `false` if the candidate was
  /// already taken.
  Future<bool> _claimCandidate(String myUid, String candidateId) async {
    try {
      final matchRef = _matches.doc();
      final channelName = 'voom_${matchRef.id}';

      await _db.runTransaction((txn) async {
        final mySnap = await txn.get(_queue.doc(myUid));
        final theirSnap = await txn.get(_queue.doc(candidateId));

        if (!mySnap.exists ||
            mySnap.data()?['status'] != 'waiting' ||
            !theirSnap.exists ||
            theirSnap.data()?['status'] != 'waiting') {
          throw Exception('candidate_unavailable');
        }

        txn.set(matchRef, {
          'user1Id': myUid,
          'user2Id': candidateId,
          'channelName': channelName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });

        txn.update(_queue.doc(myUid), {
          'status': 'matched',
          'matchId': matchRef.id,
        });

        txn.update(_queue.doc(candidateId), {
          'status': 'matched',
          'matchId': matchRef.id,
        });
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the match document and completes the pending [_matchCompleter].
  Future<void> _resolveMatch(String matchId, String myUid) async {
    try {
      _queueListener?.cancel();
      _queueListener = null;

      final matchDoc = await _matches.doc(matchId).get();
      if (!matchDoc.exists) return;

      final data = matchDoc.data()!;
      final partnerId = data['user1Id'] == myUid
          ? data['user2Id'] as String
          : data['user1Id'] as String;

      if (!(_matchCompleter?.isCompleted ?? true)) {
        _matchCompleter!.complete(MatchResult(
          matchedUserId: partnerId,
          channelName: data['channelName'] as String,
          matchId: matchId,
        ));
      }
    } catch (e) {
      if (!(_matchCompleter?.isCompleted ?? true)) {
        _matchCompleter!.completeError(e);
      }
    }
  }

  Future<void> _removeFromQueue(String uid) async {
    await _queue.doc(uid).delete().catchError((_) {});
  }
}