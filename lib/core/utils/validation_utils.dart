class ValidationUtils {
  // Test accounts that should bypass heuristic checks
  static const List<String> testAccounts = [
    "owner1@outlook.com",
    "owner2@gmail.com",
    "muzammil0369@outlook.com",
    "mudassir@gmail.com"
  ];

  static bool isValidEmail(String email) {
    if (testAccounts.contains(email.toLowerCase())) {
      return true;
    }

    // Basic syntax validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // Heuristic: Check for common "fake" patterns like sequential letters
    final localPart = email.split('@')[0].toLowerCase();
    
    // Block very short local parts (e.g., 'a@...')
    if (localPart.length < 3) return false;

    // Block obvious patterns (e.g., 'abc', 'qwer', 'asdf')
    if (localPart.contains('abc') || 
        localPart.contains('123') || 
        localPart.contains('qwerty')) {
      return false;
    }

    return true;
  }
}
