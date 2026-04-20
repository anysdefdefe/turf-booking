# Turf Booking Application

## Overview
Turf Booking Application is a full-stack platform designed to streamline the discovery, management, and booking of sports courts. It supports three distinct user roles-customers, stadium owners, and administrators each with tailored workflows and permissions.

The system is built with a focus on scalability, clean architecture, and role-based access control, enabling a complete end-to-end booking experience.

---

## Features

### Customer Experience
- Discover and browse available stadiums and courts with filtering options  
- View detailed court information including pricing and availability  
- Book courts using an hourly slot-based system  
- Manage booking history with cancellation support  

### Owner Management
- Onboard and manage stadium listings with multiple courts  
- Configure court details such as pricing, timings, and amenities  
- Track bookings and monitor revenue performance  
- Create and manage maintenance slots for courts  

### Admin Control
- Review and approve or reject stadium owner applications  
- Manage platform users and assign roles  
- Monitor overall platform activity through an admin dashboard  

### System Capabilities
- Role-based access control (Customer, Owner, Admin)  
- Conflict-free booking validation system  
- Maintenance slot enforcement during booking  
- Dummy payment flow for MVP-level testing  

---

## Tech Stack
- Flutter (Frontend application)  
- Supabase (Authentication, Database, Row Level Security)  
- GoRouter (Navigation and routing)  
- Feature-based modular architecture  

---

## Status
This is the MVP release of the application. It is stable and functional across all primary user roles and is ready for real-world testing, feedback collection, and iterative improvements.
