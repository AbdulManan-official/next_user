import 'package:flutter/material.dart';

enum MoveStatus { inTransit, scheduled, completed, cancelled }

enum PropertyType {
  studio,
  bed1Flat,
  bed2Flat,
  bed3House,
  bed4House,
  bed5PlusEstate,
  officeCommercial,
}

extension PropertyTypeExt on PropertyType {
  String get label {
    switch (this) {
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.bed1Flat:
        return '1-Bed Flat';
      case PropertyType.bed2Flat:
        return '2-Bed Flat';
      case PropertyType.bed3House:
        return '3-Bed House';
      case PropertyType.bed4House:
        return '4-Bed House';
      case PropertyType.bed5PlusEstate:
        return '5+ Bed / Estate';
      case PropertyType.officeCommercial:
        return 'Office / Commercial';
    }
  }

  int get basePrice {
    switch (this) {
      case PropertyType.studio:
        return 650;
      case PropertyType.bed1Flat:
        return 1100;
      case PropertyType.bed2Flat:
        return 1900;
      case PropertyType.bed3House:
        return 3110;
      case PropertyType.bed4House:
        return 4470;
      case PropertyType.bed5PlusEstate:
        return 6200;
      case PropertyType.officeCommercial:
        return 3800;
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.studio:
        return Icons.single_bed_rounded;
      case PropertyType.bed1Flat:
      case PropertyType.bed2Flat:
        return Icons.apartment_rounded;
      case PropertyType.bed3House:
      case PropertyType.bed4House:
      case PropertyType.bed5PlusEstate:
        return Icons.holiday_village_rounded;
      case PropertyType.officeCommercial:
        return Icons.business_rounded;
    }
  }
}

class MoveServiceItem {
  final String id;
  final String title;
  final String description;
  final int price;
  bool isSelected;

  MoveServiceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.isSelected = false,
  });

  MoveServiceItem copyWith({bool? isSelected}) {
    return MoveServiceItem(
      id: id,
      title: title,
      description: description,
      price: price,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class MoveModel {
  final String ref;
  final String title;
  final String dateString;
  final String fromAddress;
  final String toAddress;
  final int totalAmount;
  final MoveStatus status;
  final PropertyType propertyType;
  final List<MoveServiceItem> services;
  final String? timeSlot;
  final String? notes;
  final double rating;
  final String crewLeadName;
  final String crewLeadInitials;
  final double crewRating;
  final String vehicleName;

  MoveModel({
    required this.ref,
    required this.title,
    required this.dateString,
    required this.fromAddress,
    required this.toAddress,
    required this.totalAmount,
    required this.status,
    required this.propertyType,
    this.services = const [],
    this.timeSlot,
    this.notes,
    this.rating = 5.0,
    this.crewLeadName = 'Tomasz Kowalski',
    this.crewLeadInitials = 'TK',
    this.crewRating = 4.98,
    this.vehicleName = 'Luton 7.5t · NG21',
  });

  String get id => ref;
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String time;
  final String? imagePath;
  final String? videoPath;
  final bool isLocation;
  final double? latitude;
  final double? longitude;
  final String? documentPath;
  final String? documentName;
  final String senderName;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
    this.videoPath,
    this.isLocation = false,
    this.latitude,
    this.longitude,
    this.documentPath,
    this.documentName,
    this.senderName = 'You',
    this.isRead = true,
  });
}

class ReferralItem {
  final String initials;
  final String name;
  final String status;
  final String amount;

  const ReferralItem({
    required this.initials,
    required this.name,
    required this.status,
    required this.amount,
  });
}
