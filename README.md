# AttenAI - Attendance Management System

Hajiri is a comprehensive Flutter-based attendance management application designed for educational institutions. It allows teachers and administrators to manage classes, students, and attendance records efficiently.

## Features

- **Class Management**: Create, edit, and manage multiple classes
- **Student Management**: Add students to classes with roll numbers
- **Attendance Tracking**: Take daily attendance with various status options (present, absent, late, excused)
- **Statistics & Reports**: View attendance statistics and generate detailed PDF reports
- **Calendar View**: Track attendance records with an intuitive calendar interface

## PDF Report Generation

The app includes a powerful PDF reporting system that generates comprehensive attendance reports for any class. These reports include:

1. **Cover Page**: Class details and report period
2. **Summary Statistics**: Monthly and all-time attendance statistics
3. **Student Details**: Individual student attendance records with percentages
4. **Daily Records**: Day-by-day attendance breakdown

To generate a report:

1. Navigate to a class's attendance screen
2. Tap the chart icon to view statistics
3. Click "Export Report" to generate the PDF
4. Share the PDF via the device's sharing options

[Learn more about PDF reporting](docs/PDF_REPORTING_GUIDE.md)

## Getting Started

This project uses Flutter. To run the application:

```bash
flutter pub get
flutter run
```

## Dependencies

The application uses several key packages:

- flutter_riverpod for state management
- hive for local data storage
- pdf and share_plus for report generation
- table_calendar for calendar views
