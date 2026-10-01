import 'package:flutter/material.dart';
import '../models/service_model.dart';

/// User-side data and API service.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Future<List<ServiceModel>> fetchFeaturedServices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ServiceModel(
        id: '1',
        title: 'VIP Booking',
        description: 'Exclusive reservation privileges at elite venues.',
        icon: Icons.stars_rounded,
        price: 150.0,
      ),
      ServiceModel(
        id: '2',
        title: 'Luxury Chauffeur',
        description: 'First-class private transport on demand.',
        icon: Icons.directions_car_rounded,
        price: 200.0,
      ),
      ServiceModel(
        id: '3',
        title: 'Private Concierge',
        description: '24/7 dedicated personal assistant.',
        icon: Icons.room_service_rounded,
        price: 300.0,
      ),
      ServiceModel(
        id: '4',
        title: 'Premium Assistance',
        description: 'Round-the-clock priority client support.',
        icon: Icons.support_agent_rounded,
      ),
    ];
  }
}
