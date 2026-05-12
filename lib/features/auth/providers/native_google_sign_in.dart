import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> nativeGoogleSignIn() async {
  final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  // openid is implicit in ID token auth — don't put it in OAuth scope requests
  const authScopes = ['email', 'profile'];

  final googleSignIn = GoogleSignIn.instance;

  await googleSignIn.initialize(
    serverClientId:
        (webClientId != null && webClientId.isNotEmpty) ? webClientId : null,
  );

  final GoogleSignInAccount account;
  try {
    account = await googleSignIn.authenticate(
      scopeHint: authScopes,
    );
  } on GoogleSignInException catch (e) {
    throw AuthException('Google Sign-In failed: ${e.description}');
  }

  final idToken = account.authentication.idToken;

  if (idToken == null || idToken.isEmpty) {
    throw AuthException('Missing Google ID token.');
  }

  final authorization =
      await account.authorizationClient.authorizationForScopes(authScopes) ??
      await account.authorizationClient.authorizeScopes(authScopes);

  final accessToken = authorization.accessToken.isNotEmpty
      ? authorization.accessToken
      : null;

  await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken,
  );
}