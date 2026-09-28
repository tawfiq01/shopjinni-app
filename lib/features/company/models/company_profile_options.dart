/// Curated option lists shared by the Shop Settings form and the setup
/// wizard's Shop Information step — short lists on purpose (not a full
/// IANA timezone / ISO currency picker), matched to where this app is
/// actually used.
class CompanyProfileOptions {
  static const List<String> currencies = ['BDT', 'USD', 'INR', 'EUR'];

  static const List<String> timezones = ['Asia/Dhaka', 'Asia/Kolkata', 'Asia/Dubai', 'UTC'];
}
