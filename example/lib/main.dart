// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// EASY FIRESTORE EXAMPLE
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart' show Firebase;

import 'package:easy_firestore/easy_firestore.dart' as fs;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<void> main() async {
  await Firebase.initializeApp();
  FirebaseAuth.instance.signInAnonymously().then((_) async {
    // Create a new document.
    await fs.setDoc(
      "accounts",
      "default_user",
      {"name_display": "default"},
    );
    // Copy the newly created document.
    await fs.copyDoc1(
      "accounts",
      "default_user",
      "accounts",
      "default_user_copy",
    );
    // Delete the original document via a transaction.
    await fs.deleteDocTr(
      "accounts",
      "default_user",
    );
  });
  runApp(const MaterialApp(home: const Text("Easy Firestore Example")));
}
