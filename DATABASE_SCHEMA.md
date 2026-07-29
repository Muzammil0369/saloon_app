# Firestore Database Schema - Glambook

This document outlines the Firestore structure for the Glambook application.

## 1. users
Contains general information for all users (Customers, Owners, Admins).
- `uid`: string (Document ID)
- `name`: string
- `email`: string
- `role`: string ('customer', 'owner', 'admin')
- `phoneNumber`: string
- `userProfileImage`: string (URL)
- `createdAt`: timestamp
- `walletBalance`: double

## 2. owners (Salons)
Contains details for salon owners and their salons.
- `ownerId`: string (Document ID)
- `salonName`: string
- `ownerName`: string
- `address`: string
- `category`: string
- `phoneNumber`: string
- `thumbnail`: string (URL)
- `salonPhotos`: array (strings, URLs)
- `rating`: double
- `reviewCount`: int
- `isOpenNow`: boolean
- `isCompleted`: boolean (Flag for profile completion)
- `status`: string ('pending', 'approved', 'rejected')
- `services`: array of maps (embedded services)
    - `id`: string
    - `name`: string
    - `price`: int
    - `duration`: int

## 3. services
(Optional - for salons using a separate services collection)
- `serviceId`: string (Document ID)
- `ownerId`: string
- `serviceName`: string
- `price`: int
- `duration`: int
- `isActive`: boolean
- `category`: string

## 4. bookings
- `bookingId`: string (Document ID)
- `customerId`: string
- `customerName`: string
- `ownerId`: string
- `salonName`: string
- `services`: array of maps (selected services)
- `totalPrice`: int
- `date`: timestamp
- `timeSlot`: string
- `staffId`: string
- `status`: string ('pending', 'confirmed', 'completed', etc.)
- `createdAt`: timestamp

## 5. transactions
- `id`: string (Document ID)
- `userId`: string
- `userType`: string
- `type`: string ('cash_payment', 'digital_payment', etc.)
- `status`: string
- `amount`: double
- `description`: string
- `metadata`: map

## 6. ads (Offers)
- `ownerId`: string (Document ID)
- `offerTitle`: string
- `percentOff`: double (Discount percentage)
- `expiresAt`: timestamp
- `selectedServices`: array of maps (services included in offer)
- `isActive`: boolean
