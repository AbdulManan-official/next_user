import 'package:flutter/material.dart';
import '../models/move_model.dart';

/// Central in-memory reactive state manager for the Luxury Moving prototype.
class MoveStore extends ChangeNotifier {
  MoveStore._();
  static final MoveStore instance = MoveStore._();

  // ---------------------------------------------------------------------------
  // Active and Past Moves
  // ---------------------------------------------------------------------------
  MoveModel? activeMove = MoveModel(
    ref: 'NG-1042',
    title: '4-Bed House Move',
    dateString: 'Sat, 21 June 2026 · 08:00 AM',
    fromAddress: '12 Kingsway, Slough',
    toAddress: 'Rosewood Manor, Windsor',
    totalAmount: 4850,
    status: MoveStatus.inTransit,
    propertyType: PropertyType.bed4House,
    timeSlot: 'Morning 8–12',
    services: [
      MoveServiceItem(
        id: 'pack',
        title: 'Full Packing Service',
        description: 'White-glove wrapping & boxing',
        price: 380,
        isSelected: true,
      ),
      MoveServiceItem(
        id: 'ins',
        title: 'Premium Insurance',
        description: 'Full replacement cover',
        price: 95,
        isSelected: true,
      ),
    ],
  );

  final List<MoveModel> scheduledMoves = [
    MoveModel(
      ref: 'NG-1043',
      title: '3-Bed House Move',
      dateString: '24 June 2026 · Morning 8–12',
      fromAddress: '14 Kensington High St, London',
      toAddress: 'Oakwood Estate, Surrey',
      totalAmount: 3450,
      status: MoveStatus.scheduled,
      propertyType: PropertyType.bed3House,
      timeSlot: 'Morning 8–12',
      services: [
        MoveServiceItem(
          id: 'pack',
          title: 'Full Packing Service',
          description: 'White-glove wrapping & boxing',
          price: 380,
          isSelected: true,
        ),
      ],
    ),
  ];

  final List<MoveModel> pastMoves = [
    MoveModel(
      ref: 'NG-0981',
      title: '2-Bed Flat Move',
      dateString: '14 March 2026',
      fromAddress: 'Reading Central',
      toAddress: 'London SW1',
      totalAmount: 2200,
      status: MoveStatus.completed,
      propertyType: PropertyType.bed2Flat,
      rating: 5.0,
    ),
    MoveModel(
      ref: 'NG-0840',
      title: 'Studio Relocation',
      dateString: '22 November 2025',
      fromAddress: 'Oxford High St',
      toAddress: 'Bristol Harbourside',
      totalAmount: 850,
      status: MoveStatus.completed,
      propertyType: PropertyType.studio,
      rating: 5.0,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Booking Draft State
  // ---------------------------------------------------------------------------
  PropertyType selectedProperty = PropertyType.bed3House;
  String fromAddress = '12 Kingsway, Slough';
  String toAddress = 'Rosewood Manor, Windsor';
  String preferredDate = '24 June 2026';
  String selectedTimeSlot = 'Morning 8–12';
  String notes = 'Please handle antique grandfather clock with extra care.';

  List<MoveServiceItem> availableServices = [
    MoveServiceItem(
      id: 'pack',
      title: 'Full Packing Service',
      description: 'White-glove wrapping & boxing',
      price: 380,
      isSelected: true,
    ),
    MoveServiceItem(
      id: 'store',
      title: 'Secure Storage',
      description: 'Climate-controlled vault',
      price: 220,
      isSelected: false,
    ),
    MoveServiceItem(
      id: 'dismantle',
      title: 'Furniture Dismantle',
      description: 'Assemble & reassemble',
      price: 160,
      isSelected: false,
    ),
    MoveServiceItem(
      id: 'ins',
      title: 'Premium Insurance',
      description: 'Full replacement cover',
      price: 95,
      isSelected: true,
    ),
  ];

  void setProperty(PropertyType prop) {
    selectedProperty = prop;
    notifyListeners();
  }

  void setRoute({
    required String from,
    required String to,
    required String date,
    required String timeSlot,
    String? additionalNotes,
  }) {
    fromAddress = from;
    toAddress = to;
    preferredDate = date;
    selectedTimeSlot = timeSlot;
    if (additionalNotes != null) notes = additionalNotes;
    notifyListeners();
  }

  void toggleService(String serviceId) {
    final idx = availableServices.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      availableServices[idx].isSelected = !availableServices[idx].isSelected;
      notifyListeners();
    }
  }

  int get quoteBasePrice => selectedProperty.basePrice;

  int get quoteServicesTotal {
    return availableServices
        .where((s) => s.isSelected)
        .fold(0, (sum, s) => sum + s.price);
  }

  int get quoteGrandTotal => quoteBasePrice + quoteServicesTotal;

  /// Confirm booking: adds NG-1043 to active/upcoming moves
  void confirmNewBooking() {
    final newMove = MoveModel(
      ref: 'NG-1043',
      title: '${selectedProperty.label} Move',
      dateString: '$preferredDate · $selectedTimeSlot',
      fromAddress: fromAddress.isNotEmpty ? fromAddress : '12 Kingsway, Slough',
      toAddress: toAddress.isNotEmpty ? toAddress : 'Rosewood Manor, Windsor',
      totalAmount: quoteGrandTotal,
      status: MoveStatus.scheduled,
      propertyType: selectedProperty,
      timeSlot: selectedTimeSlot,
      notes: notes,
      services: availableServices.where((s) => s.isSelected).toList(),
    );

    // Insert into scheduled moves list and set active
    scheduledMoves.insert(0, newMove);
    activeMove = newMove;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Referrals Mock Data
  // ---------------------------------------------------------------------------
  final List<ReferralItem> referrals = const [
    ReferralItem(initials: 'MA', name: 'Marcus A.', status: 'Moved', amount: '+£50'),
    ReferralItem(initials: 'PK', name: 'Priya K.', status: 'Booked', amount: '+£50'),
    ReferralItem(initials: 'SR', name: 'Sofia R.', status: 'Pending', amount: '—'),
    ReferralItem(initials: 'DF', name: 'Daniel F.', status: 'Moved', amount: '+£50'),
  ];

  // ---------------------------------------------------------------------------
  // Chat Conversations
  // ---------------------------------------------------------------------------
  final List<ChatMessage> conciergeMessages = [
    ChatMessage(
      id: 'c1',
      text: 'Good morning Eleanor, how can we help with your move today?',
      isUser: false,
      time: '09:15 AM',
    ),
  ];

  final List<ChatMessage> crewMessages = [
    ChatMessage(
      id: 'cr1',
      text: "Hi Eleanor, we're on the road, arriving around 13:00.",
      isUser: false,
      time: '10:35 AM',
    ),
  ];

  void addConciergeMessage(String text, {required bool isUser}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    conciergeMessages.add(
      ChatMessage(
        id: now.millisecondsSinceEpoch.toString(),
        text: text,
        isUser: isUser,
        time: timeStr,
      ),
    );
    notifyListeners();
  }

  void addCrewMessage(String text, {required bool isUser}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    crewMessages.add(
      ChatMessage(
        id: now.millisecondsSinceEpoch.toString(),
        text: text,
        isUser: isUser,
        time: timeStr,
      ),
    );
    notifyListeners();
  }
}
