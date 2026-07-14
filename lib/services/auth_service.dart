import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_advance/model/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;
  bool _isLoading = true;
  String? _verificationId;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _getUserData(firebaseUser.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        await _updateOnlineStatus(true);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error getting user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> sendOTP(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sipahi.page.link/login',
          handleCodeInApp: true,
          iOSBundleId: 'com.sipahi.app',
          androidPackageName: 'com.sipahi.app',
          androidInstallApp: true,
          androidMinimumVersion: '1',
        ),
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);

      // Generate 6-digit OTP for demo
      String otp = (Random().nextInt(900000) + 100000).toString();
      await prefs.setString('otp', otp);

      return otp;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOTP = prefs.getString('otp');

      if (savedOTP == otp) {
        // Sign in with email link
        await _auth
            .signInWithEmailAndPassword(
          email: email,
          password: otp,
        )
            .catchError((e) async {
          // If user doesn't exist, create account
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: otp,
          );
        });

        await _createUserDocument(email, otp);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<void> _createUserDocument(String email, String otp) async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': email,
        'displayName': email.split('@')[0],
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _updateOnlineStatus(false);
    await _auth.signOut();
  }

  Future<void> updateFCMToken(String? token) async {
    if (_user != null && token != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'fcmToken': token,
      });
    }
  }
}
