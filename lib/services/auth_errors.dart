class AuthErrorMapper {
  static String messageFromCode(String errorMessage) {
    final msg = errorMessage.toLowerCase();
    print("Auth error: $msg");

    // INVALID EMAIL
    if (msg.contains("invalid email") || msg.contains("email format")) {
      return "The email address is not valid.";
    }

    // INVALID CREDENTIALS
    if (msg.contains("invalid login credentials")) {
      return "Incorrect email or password.";
    }

    // PASSWORD TOO SHORT
    if (msg.contains("password should be at least 6 characters")) {
      return "Password must be at least 6 characters long.";
    }

    // USER NOT FOUND
    if (msg.contains("user not found")) {
      return "No account found with this email address.";
    }

    // EMAIL NOT VERIFIED
    if (msg.contains("email not confirmed")) {
      return "You must verify your email before logging in.";
    }

    // EMAIL ALREADY REGISTERED
    if (msg.contains("user already registered") ||
        msg.contains("duplicate key")) {
      return "An account with this email already exists.";
    }

    // WEAK PASSWORD
    if (msg.contains("weak password")) {
      return "The password is too weak.";
    }

    // NETWORK ERROR
    if (msg.contains("network") || msg.contains("timeout")) {
      return "No internet connection.";
    }

    // UNKNOWN ERROR
    return "An unexpected error occurred. "
        "(Code: ${msg.hashCode}) "
        "(Details: $errorMessage)";
  }
}