import 'package:flutter/material.dart';

/// Model representing a service offered to the user.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.price,
    this.rating = 5.0,
    this.isAvailable = true,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final double? price;
  final double rating;
  final bool isAvailable;
}
