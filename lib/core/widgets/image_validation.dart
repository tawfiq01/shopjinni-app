const maxUploadImageBytes = 2 * 1024 * 1024;

/// Returns an error message if [byteLength] exceeds the upload size limit,
/// or null if the size is acceptable.
String? validateImageSize(int byteLength) {
  if (byteLength > maxUploadImageBytes) {
    return 'Image must be 2MB or smaller.';
  }
  return null;
}
