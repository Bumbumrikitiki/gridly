import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required bool firebaseEnabled})
    : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;

  bool _initialized = false;
  bool _isBusy = false;
  String? _errorMessage;
  User? _firebaseUser;
  bool _isPro = false;
  String? _profileDisplayName;
  String? _profileEmail;
  String? _companyName;
  String? _phoneNumber;

  StreamSubscription<User?>? _authSubscription;

  bool get firebaseEnabled => _firebaseEnabled;
  bool get initialized => _initialized;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _firebaseUser != null;
  bool get isPro => _isPro;
  User? get firebaseUser => _firebaseUser;
  String get email =>
      (_profileEmail ?? _firebaseUser?.email ?? '').trim();
  String get companyName => (_companyName ?? '').trim();
  String get phoneNumber => (_phoneNumber ?? '').trim();

  String get displayName {
    final profileName = _profileDisplayName?.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }

    final name = _firebaseUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final email = _firebaseUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'Użytkownik';
  }

  void init() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!_firebaseEnabled) {
      _errorMessage =
          'Firebase nie jest skonfigurowany. Logowanie i subskrypcje są niedostępne.';
      notifyListeners();
      return;
    }

    _firebaseUser = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user == null) {
        _isPro = false;
        notifyListeners();
        return;
      }
      await _ensureAndLoadProfile(user);
      notifyListeners();
    });

    if (_firebaseUser != null) {
      unawaited(refreshProfile());
    }
  }

  Future<void> refreshProfile() async {
    final user = _firebaseUser;
    if (!_firebaseEnabled || user == null) {
      return;
    }
    await _ensureAndLoadProfile(user);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (!_firebaseEnabled) {
      _errorMessage =
          'Firebase nie jest skonfigurowany. Dodaj konfigurację Firebase, aby logować użytkowników.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: <String>['email']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          _setBusy(false);
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Błąd logowania Firebase Auth.';
    } catch (e) {
      _errorMessage = 'Nie udało się zalogować przez Google: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    if (!_firebaseEnabled) {
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
      _isPro = false;
      _profileDisplayName = null;
      _profileEmail = null;
      _companyName = null;
      _phoneNumber = null;
    } catch (e) {
      _errorMessage = 'Nie udało się wylogować: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateProfileData({
    required String displayName,
    required String companyName,
    required String phoneNumber,
  }) async {
    if (!_firebaseEnabled || _firebaseUser == null) {
      _errorMessage = 'Zaloguj się, aby zaktualizować dane profilu.';
      notifyListeners();
      return;
    }

    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Nazwa użytkownika nie może być pusta.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    try {
      final uid = _firebaseUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await docRef.set({
        'displayName': trimmedName,
        'companyName': companyName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firebaseUser!.updateDisplayName(trimmedName);
      _profileDisplayName = trimmedName;
      _companyName = companyName.trim();
      _phoneNumber = phoneNumber.trim();
    } catch (e) {
      _errorMessage = 'Nie udało się zapisać danych profilu: $e';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> _ensureAndLoadProfile(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'companyName': '',
        'phoneNumber': '',
        'isPro': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _isPro = false;
      _profileDisplayName = user.displayName?.trim();
      _profileEmail = user.email?.trim();
      _companyName = '';
      _phoneNumber = '';
      return;
    }

    final data = snapshot.data();
    final isProValue = data?['isPro'];
    _isPro = isProValue is bool ? isProValue : false;
    _profileDisplayName = (data?['displayName'] as String?)?.trim();
    _profileEmail = (data?['email'] as String?)?.trim() ?? user.email?.trim();
    _companyName = (data?['companyName'] as String?)?.trim();
    _phoneNumber = (data?['phoneNumber'] as String?)?.trim();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
