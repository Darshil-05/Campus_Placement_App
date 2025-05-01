const String serverurl = 'http://192.168.103.209:8000';
late String role ;
late String email;
String name ='';
String domain=' ';

String determineEmailType(String email) {

  // return 'faculty';
  // Check if the email is not null or empty
  if (email == null || email.isEmpty) {
    return 'Invalid email';
  }
  
  // Check if email has an @ symbol
  if (!email.contains('@')) {
    return 'Invalid email format';
  }
  
  // Check the domain suffix for classification
  if (email.endsWith('@charusat.edu.in')) {
    return 'student';
  } else if (email.endsWith('@charusat.ac.in')) {
    return 'faculty';
  } else {
    return 'Unknown';
  }
}

String extractIdFromEmail(String email) {
  // Check if the email is not null or empty
  if (email == null || email.isEmpty) {
    return '';
  }
  
  // Split the email by @ and take the first part
  final parts = email.split('@');
  if (parts.length > 0) {
    return parts[0];
  }
  
  // Return empty string if no @ symbol is foun d
  return '';
}