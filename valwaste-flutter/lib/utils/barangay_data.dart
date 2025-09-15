// Valenzuela City Barangays
class BarangayData {
  static const List<String> valenzuelaBarangays = [
    'Arkong Bato',
    'Bagbaguin',
    'Balangkas',
    'Bignay',
    'Bisig',
    'Canumay East',
    'Canumay West',
    'Coloong',
    'Dalandanan',
    'Gen. T. De Leon',
    'Hen. T. De Leon',
    'Isla',
    'Karuhatan',
    'Lawang Bato',
    'Lingunan',
    'Mabolo',
    'Malanday',
    'Malinta',
    'Mapulang Lupa',
    'Marulas',
    'Maysan',
    'Palasan',
    'Parada',
    'Pariancillo Villa',
    'Paso de Blas',
    'Pasolo',
    'Poblacion',
    'Polo',
    'Punturin',
    'Rincon',
    'Tagalag',
    'Ugong',
    'Viente Reales',
    'Wawang Pulo',
  ];

  // Get nearest barangay from coordinates
  static String getNearestBarangay(double latitude, double longitude) {
    // Barangay coordinates mapping (approximate centers)
    final Map<String, Map<String, double>> barangayCoordinates = {
      'Arkong Bato': {'lat': 14.7113, 'lng': 120.9830},
      'Bagbaguin': {'lat': 14.7574, 'lng': 120.9422},
      'Balangkas': {'lat': 14.6572, 'lng': 120.9833},
      'Bignay': {'lat': 14.7200, 'lng': 120.9600},
      'Bisig': {'lat': 14.6950, 'lng': 120.9750},
      'Canumay East': {'lat': 14.7350, 'lng': 120.9650},
      'Canumay West': {'lat': 14.7300, 'lng': 120.9600},
      'Coloong': {'lat': 14.6800, 'lng': 120.9700},
      'Dalandanan': {'lat': 14.6733, 'lng': 120.9667},
      'Gen. T. De Leon': {'lat': 14.6900, 'lng': 120.9800},
      'Hen. T. De Leon': {'lat': 14.6850, 'lng': 120.9750},
      'Isla': {'lat': 14.6600, 'lng': 120.9850},
      'Karuhatan': {'lat': 14.6950, 'lng': 120.9900},
      'Lawang Bato': {'lat': 14.7000, 'lng': 120.9600},
      'Lingunan': {'lat': 14.7400, 'lng': 120.9500},
      'Mabolo': {'lat': 14.6700, 'lng': 120.9800},
      'Malanday': {'lat': 14.6650, 'lng': 120.9750},
      'Malinta': {'lat': 14.6800, 'lng': 120.9650},
      'Mapulang Lupa': {'lat': 14.6900, 'lng': 120.9700},
      'Marulas': {'lat': 14.6750, 'lng': 120.9850},
      'Maysan': {'lat': 14.6850, 'lng': 120.9600},
      'Palasan': {'lat': 14.7100, 'lng': 120.9700},
      'Parada': {'lat': 14.7050, 'lng': 120.9750},
      'Pariancillo Villa': {'lat': 14.6950, 'lng': 120.9650},
      'Paso de Blas': {'lat': 14.6700, 'lng': 120.9600},
      'Pasolo': {'lat': 14.7150, 'lng': 120.9550},
      'Poblacion': {'lat': 14.6900, 'lng': 120.9750},
      'Polo': {'lat': 14.6800, 'lng': 120.9800},
      'Punturin': {'lat': 14.7250, 'lng': 120.9450},
      'Rincon': {'lat': 14.7300, 'lng': 120.9500},
      'Tagalag': {'lat': 14.7350, 'lng': 120.9550},
      'Ugong': {'lat': 14.7450, 'lng': 120.9400},
      'Viente Reales': {'lat': 14.7200, 'lng': 120.9650},
      'Wawang Pulo': {'lat': 14.6600, 'lng': 120.9700},
    };

    // Default to first barangay if no coordinates
    if (latitude == 0 && longitude == 0) {
      return valenzuelaBarangays[0];
    }

    // Find nearest barangay based on distance
    String nearestBarangay = valenzuelaBarangays[0];
    double minDistance = double.infinity;

    for (final entry in barangayCoordinates.entries) {
      final barangayLat = entry.value['lat'] ?? 0;
      final barangayLng = entry.value['lng'] ?? 0;
      
      // Calculate distance using simple Euclidean distance
      final distance = _calculateDistance(
        latitude, longitude, 
        barangayLat, barangayLng
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestBarangay = entry.key;
      }
    }

    return nearestBarangay;
  }

  // Simple distance calculation
  static double _calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    final latDiff = lat2 - lat1;
    final lonDiff = lon2 - lon1;
    return (latDiff * latDiff + lonDiff * lonDiff);
  }

  // Format location display
  static String formatLocationDisplay(dynamic location) {
    if (location == null) return 'Unknown Location';
    
    final locationStr = location.toString();
    
    // Check if it's coordinates
    if (locationStr.contains(',')) {
      final parts = locationStr.split(',');
      if (parts.length == 2) {
        try {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          return getNearestBarangay(lat, lng);
        } catch (e) {
          // Not valid coordinates, return as is
        }
      }
    }
    
    // Check if it already contains a barangay name
    for (final barangay in valenzuelaBarangays) {
      if (locationStr.toLowerCase().contains(barangay.toLowerCase())) {
        return barangay;
      }
    }
    
    // Return cleaned location string
    if (locationStr.toLowerCase().contains('valenzuela')) {
      final parts = locationStr.split(',');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }
    
    return locationStr;
  }
}
