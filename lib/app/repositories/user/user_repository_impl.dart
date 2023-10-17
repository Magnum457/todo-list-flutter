import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../exceptions/auth_exceptions.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth _firebaseAuth;

  UserRepositoryImpl({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  @override
  Future<User?> register(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      if (e.code == 'email-already-in-use') {
        final loginTypes =
            await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (loginTypes.isEmpty || loginTypes.contains('password')) {
          throw AuthException(
              message: 'E-mail já utilizado, por favor escolha outro e-mail.');
        } else {
          throw AuthException(
              message:
                  'Você se cadastrou no TodoList pelo Google, por favor utilize ele para entrar!!!');
        }
      } else {
        throw AuthException(message: e.message ?? 'Erro ao registrar usuário');
      }
    }
  }

  @override
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      return userCredential.user;
    } on PlatformException catch (e, s) {
      debugPrint(e.message);
      debugPrint(s.toString());
      throw AuthException(message: e.message ?? 'Erro ao realizar o login.');
    } on FirebaseAuthException catch (e, s) {
      debugPrint(e.message);
      debugPrint(s.toString());
      if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        throw AuthException(message: 'Login ou senha inválidos.');
      }
      throw AuthException(message: e.message ?? 'Erro ao realizar o login.');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      var loginMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email);

      if (loginMethods.isEmpty || loginMethods.contains('password')) {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
      } else {
        throw AuthException(
            message:
                'Você se cadastrou no TodoList pelo Google, não pode ser resetado a senha!!!');
      }
    } on PlatformException catch (e) {
      debugPrint(e.message);
      throw AuthException(message: 'Erro ao resetar a senha.');
    }
  }

  @override
  Future<User?> googleLogin() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final loginMethods =
            await _firebaseAuth.fetchSignInMethodsForEmail(googleUser.email);

        if (loginMethods.contains('password')) {
          throw AuthException(
              message:
                  'Você utilizou o e-mail para cadastrar no TodoList, caso tenha esquecido a senha, por favor clique em esquecia senha');
        } else {
          final googleAuth = await googleUser.authentication;
          final firebaseCredential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
          var userCredential =
              await _firebaseAuth.signInWithCredential(firebaseCredential);
          return userCredential.user;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthException(
            message:
                'Você já tem uma credencial cadastrada, por favor utilize ela para entrar!!!');
      } else {
        throw AuthException(message: 'Erro ao realizar o login.');
      }
    }
  }
}
