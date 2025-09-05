import 'package:flutter/foundation.dart'; // For debugPrint

class Expense {
  final int? id;
  final int? userId; // Assuming this comes from your user context
  final String name;
  final double amount;
  final int categoryId;

  // --- Recurring Fields ---
  final bool isRecurring;
  final DateTime? startDate; // For recurring: first occurrence date. For one-time: transaction date.
  final DateTime? endDate;   // For recurring: last possible occurrence date (inclusive). Nullable.
  final String? recurringFrequency; // e.g., 'monthly', 'weekly', 'yearly'. Nullable.
  // --- End Recurring Fields ---

  Expense({
    this.id,
    this.userId,
    required this.name,
    required this.amount,
    required this.categoryId,
    // Default values for new fields
    this.isRecurring = false,
    this.startDate, // Required if isRecurring is true, potentially required always?
    this.endDate,
    this.recurringFrequency,
  });

  Map<String, dynamic> toMap() {
    // Debug print before creating map
    // debugPrint('Expense.toMap: id=$id, name=$name, amount=$amount, categoryId=$categoryId, isRecurring=$isRecurring, startDate=$startDate, endDate=$endDate, freq=$recurringFrequency');
    return {
      // Don't include id for inserts, only for updates if needed (handled by VM)
      // 'id': id, // ID is usually auto-generated or used only in WHERE clauses
      if (userId != null) 'userId': userId, // Ensure your Supabase uses 'userId' or 'user_id'
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'is_recurring': isRecurring,
      // Use toIso8601String for timestamp compatibility with Supabase
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(), // Will be null if endDate is null
      'recurring_frequency': recurringFrequency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    // Debug print the map received from Supabase/source
    // debugPrint('Expense.fromMap input: $map');

    // Helper to safely parse dates, returning null if invalid or null input
    DateTime? _parseDateTime(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        debugPrint('Error parsing date "$dateString": $e');
        return null; // Return null if parsing fails
      }
    }

    return Expense(
      // Use null-aware operators and casting
      id: map['id'] as int?,
      userId: map['userId'] as int?, // Match key from Supabase ('userId' or 'user_id')
      name: map['name'] as String? ?? 'Unnamed Expense', // Provide default if null
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0, // Provide default if null
      categoryId: map['categoryId'] as int? ?? 0, // Provide default or handle error
      isRecurring: map['is_recurring'] as bool? ?? false, // Default to false if null
      // Safely parse dates
      startDate: _parseDateTime(map['start_date'] as String?),
      endDate: _parseDateTime(map['end_date'] as String?),
      recurringFrequency: map['recurring_frequency'] as String?,
    );
  }

  // Optional: Add toString for easier debugging
  @override
  String toString() {
    return 'Expense(id: $id, name: $name, amount: $amount, categoryId: $categoryId, isRecurring: $isRecurring, startDate: $startDate, endDate: $endDate, frequency: $recurringFrequency)';
  }
}