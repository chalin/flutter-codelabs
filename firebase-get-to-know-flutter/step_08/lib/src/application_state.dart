import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'authentication.dart';

class GTKApplicationState extends ChangeNotifier {
  GTKApplicationState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = GTKApplicationLoginState.loggedIn;
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = [];
          snapshot.docs.forEach((document) {
            _guestBookMessages.add(
              GTKGuestBookMessage(
                name: document.data()['name'],
                message: document.data()['text'],
              ),
            );
          });
          notifyListeners();
        });
      } else {
        _loginState = GTKApplicationLoginState.loggedOut;
        _guestBookMessages = [];
        _guestBookSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  GTKApplicationLoginState _loginState;
  GTKApplicationLoginState get loginState => _loginState;

  String _email;
  String get email => _email;

  StreamSubscription<QuerySnapshot> _guestBookSubscription;
  List<GTKGuestBookMessage> _guestBookMessages = [];
  List<GTKGuestBookMessage> get guestBookMessages => _guestBookMessages;

  void startLoginFlow() {
    _loginState = GTKApplicationLoginState.emailAddress;
    notifyListeners();
  }

  void verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = GTKApplicationLoginState.password;
      } else {
        _loginState = GTKApplicationLoginState.register;
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // If sign in succeeds, FirebaseAuth.instance.userChanges() will fire
      // with new state. Alternatively, a FirebaseAuthException will be thrown
      // with an explanation as to why sign in failed.
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = GTKApplicationLoginState.emailAddress;
    notifyListeners();
  }

  void registerAccount(String email, String displayName, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user.updateProfile(displayName: displayName);
      // If registration succeeds, FirebaseAuth.instance.userChanges() will
      // fire with new state. Alternatively, a FirebaseAuthException will be
      // thrown with an explanation as to why registration failed.
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<DocumentReference> addMessageToGuestBook(String message) {
    if (_loginState != GTKApplicationLoginState.loggedIn)
      throw Exception('Must be logged in');

    return FirebaseFirestore.instance.collection('guestbook').add({
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'name': FirebaseAuth.instance.currentUser.displayName,
      'userId': FirebaseAuth.instance.currentUser.uid,
    });
  }
}

class GTKGuestBookMessage {
  GTKGuestBookMessage({@required this.name, @required this.message});
  final String name;
  final String message;
}