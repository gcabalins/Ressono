
class AuthErrorMapper {
  static String messageFromCode(String errorMessage) {
    final msg = errorMessage.toLowerCase();
    print("Auth error: $msg");

    // EMAIL NO VÁLIDO
    if (msg.contains("invalid email") || msg.contains("email format")) {
      return "El correo no es válido.";
    }

    // CONTRASEÑA INCORRECTA
    if (msg.contains("invalid login credentials")) {
      return "Correo o contraseña incorrectos.";
    }
    // CONTRASEÑA CORTA
    if (msg.contains("password should be at least 6 characters")) {
      return "La contraseña debe tener al menos 6 caracteres.";
    }

    // USUARIO NO EXISTE
    if (msg.contains("user not found")) {
      return "No existe ninguna cuenta con ese correo.";
    }

    // EMAIL NO VERIFICADO
    if (msg.contains("email not confirmed") ||
        msg.contains("email not confirmed")) {
      return "Debes verificar tu correo antes de iniciar sesión.";
    }

    // EMAIL YA REGISTRADO
    if (msg.contains("user already registered") ||
        msg.contains("duplicate key")) {
      return "Ya existe una cuenta con ese correo.";
    }

    // CONTRASEÑA DÉBIL
    if (msg.contains("weak password")) {
      return "La contraseña es demasiado débil.";
    }

    // ERROR DE RED
    if (msg.contains("network") || msg.contains("timeout")) {
      return "No hay conexión a internet.";
    }

    // ERROR DESCONOCIDO
    return "Ha ocurrido un error inesperado." + "(Código: ${msg.hashCode})" + "(errorMessage: $errorMessage)";
  }
}
