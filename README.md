# 📘 Smarter Student Reminder & Attendance App

A modern Flutter-based attendance & notes management app designed for students and teachers — powered by geofencing, Firebase, and Material 3 design.

---

## ✨ Overview

The **Student Reminder & Attendance App** streamlines attendance tracking, note-taking, and location-based insights. Designed with students and administrators in mind, it combines:

* Smart clock-in/clock-out based on geolocation
* Attendance trend analytics
* Custom geofence logic (Fixed vs Floating)
* Public and private note sharing
* Admin control over geofence and incidents

Built for class management, student accountability, and insight-driven teaching.

---

## 📲 Key Features

### 🔐 Authentication

* Firebase Auth (email-based login)
* Role-based access: Student / Admin / Teacher

### 🧽 Geofence Attendance (Core)

* **Check-in/out** only within allowed GPS radius
* **Fixed Band**: Enforced location radius
* **Floating Band**: No GPS restriction
* **Late Reason** prompt when late
* **Outside Message** before action if out-of-bounds

### 👀 Admin Geofence Profiles

* Per-student, per-day geofence editor
* Choose check-in/out location & radius
* Set Band Type: Fixed / Floating
* Set "Allow & Flag" or "Block"
* Optional outside message

### 📊 Attendance Insights

* Weekly analytics summary (present, late, absent)
* Compare vs last week
* Tags:

  * ⚠️ 2+ Absences → "At Risk"
  * ⏰ 2+ Lates → "Frequently Late"

### 📝 Notes System

* Create notes (private/public)
* Live character counter + validator
* Tagging system + chip filters
* Sort by date, title
* Public feed of student notes (timeline)
* Like & report system for public notes

### 🧑‍🎓 Profiles

* Editable profile with image crop
* Optional cover photo (collapsible header)
* Bio with live character count
* Attendance summary by user

### 📍 Incident Reports (Admin + Student)

* Location outside fixed band → triggers incident
* Stored in `geofence_incidents/`
* Admin & student views with maps, timestamps, and distances

---

## 🥪 Sample Screenshots

| Profile Page                                                                                             | Attendance Trend                                                                                         | Late Reason Dialog                                                                                       |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| ![](assets/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-10-01%20at%2022.20.22.png) | ![](assets/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-10-06%20at%2016.24.58.png) | ![](assets/screens/Simulator%20Screenshot%20-%20iPhone%2016%20Plus%20-%202025-10-06%20at%2015.37.25.png) |

---

## 🗂️ Folder Structure

```
lib/
├── src/
│   ├── models/              # Data models (attendance, geofence, user)
│   ├── services/            # Firebase, AttendanceRepo, Geo helpers
│   ├── screens/             # UI Pages (Home, Attendance, Notes)
│   ├── widgets/             # Reusable components (Cards, Charts)
│   ├── core/                # Theme, utils, helpers
│   └── main.dart
```

---

## 🛠️ Setup Instructions

1. **Clone this repo:**

   ```bash
   git clone https://github.com/YOUR_GROUP/student-reminder-app.git
   ```
2. **Add Firebase config:**

   * Replace `google-services.json` and `GoogleService-Info.plist`
   * Set up Firestore rules and indexes (refer to `rules/`)
3. **Install dependencies:**

   ```bash
   flutter pub get
   ```
4. **Run the app:**

   ```bash
   flutter run
   ```

---

## 🔐 Firebase Structure (Firestore)

```js
// users/{uid}
{
  displayName: "Mr Montaque",
  role: "student",
  bandType: "fixed",
  ...
}

// attendance/{recordId}
{
  sessionId: "...",
  studentUid: "...",
  direction: "checkin",
  status: "late",
  reason: "Traffic",
  ...
}

// geofence_incidents/{incidentId}
{
  occurredAt: Timestamp,
  bandTypeAtTime: "fixed",
  outsideMessageText: "Contact supervisor",
  ...
}
```

---

## ✅ Progress Checklist (Milestone 2)

* [x] Late Reason Prompt Dialog
* [x] Attendance Model Update (with `lateReason`)
* [x] Insights Widget (with at-risk tags)
* [x] Student Profile Attendance Stats
* [x] Admin Incident Page (WIP)
* [ ] Geofence Editor (next)

---

## 🔁 Contribution (Team)

| Name           | Feature Owned                        |
| -------------- | ------------------------------------ |
| You (Montaque) | Attendance UI, Insights, Late Reason |
| Member 2       | Notes Redesign, Tag Filters          |
| Member 3       | Profile Page, Media Uploads          |
| Member 4       | Admin Views, Incidents               |

---

## 📌 Upcoming Plans

* Build geofence profile editor
* Add incident detail view
* Exportable reports
* Final UI polish + animations

---

## 📌 References & Inspiration

* Dribbble UI: [Student Attendance Tracker](https://dribbble.com)
* Material 3: [https://m3.material.io/](https://m3.material.io/)
* Geofence logic: Firebase + GPS

---

## 🎩 Deliverables

* ✅ Final App Branch: `feature/milestone-2-attendance`
* 📸 Zoom Screenshots (submitted separately)
* 🎥 3-min demo video: [link here]
* 📄 README with setup + screenshots (✅ you're reading it!)

---

## 🙌 Thanks for reviewing!

Made with Flutter, Firebase & 💙
