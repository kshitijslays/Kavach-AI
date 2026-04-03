
<<<<<<< HEAD
KAVACH (Digital Tourist Safety & Incident Response System)

> An Immutable, AI-Driven Ecosystem for Proactive Tourist Safety and Rapid Incident Response.

| **Team Name** | **Team ID** |
| :--- | :--- |
| **KAVACH** | **135** |

## 👥 Team Members & Roles

| Member Name | Primary Role | Area of Expertise |
| :--- | :--- | :--- |
| **Yaashita** | Pitch Research Lead | Blockchain & Smart Contracts |
| **Neha Singh** | Backend Development | Presentation & Documentation |
| **Shagun Bhardwaj** | Backend Development | Data Research & Architecture |
| **Kshitij Raj** | Frontend Development | Mobile UI/UX & Blockchain Integration |

---

## 🌟 Unique Selling Proposition (USP)

Kavach moves beyond **reactive alert** systems to deliver a proactive, verified safety system.

1.  **Tamper-Proof Digital Trust:** Our core feature is the **Blockchain-Anchored Digital ID**. We use Smart Contracts to lock an immutable cryptographic hash of the tourist's KYC data, guaranteeing the identity is **100% genuine** and untampered.

2.  **Zero-Paperwork Efficiency:** We replace manual documentation with a single Digital ID, enabling **Zero-Paperwork Onboarding** and fast, **Automated E-FIR Generation** upon incident detection, drastically cutting emergency response time.

3.  **Proactive Safety Intelligence:** We use **AI to predict distress** based on live GPS tracking and behavioral anomalies, coupled with **Geo-Fencing** to alert users *before* they enter high-risk zones, allowing for pre-emptive intervention.

---

## 💡 Project Overview: A Layered Security Model

| Component | Function | Key Outcome |
| :--- | :--- | :--- |
| Mobile App (Tourist) | Real-time safety scoring, Proactive Geo-Fencing alerts, and continuous GPS live tracking. | Empowerment & Constant Monitoring. |
| Digital ID Platform | Secure KYC verification and issuance of the blockchain-linked identity. | Immutable Trust & Instant Verification. |
| Authority Dashboard | Real-time visualization of tourist clusters, alert heat maps, and incident response management. | Rapid Resource Deployment & Streamlined Investigation. |

---

## 🛠 Technical Architecture & Stack

Kavach is built on a robust, scalable, and decentralized technology stack.

### 🌐 Backend & Core Logic

| Technology | Purpose |
| :--- | :--- |
| **Node.js / Next.js** | Core API layer for handling all requests and routing. |
| **Python** | Dedicated service for the **AI/ML Anomaly Detection Engine** and Safety Score calculation. |
| **MongoDB** | Primary database for real-time storage of user profiles, travel itineraries, and location history. |
| **Firebase** | Used for secure user authentication management. |

### 🔗 Digital ID & KYC Pipeline

| Technology | Purpose |
| :--- | :--- |
| **Blockchain (Ethereum/Polygon)** | **Smart Contracts (Solidity)** for issuing and verifying the immutable hash of the Digital ID. |
| **OCR (Tesseract/MLKit)** | Used in the mobile app for fast and accurate extraction of data from KYC documents. |
| **OpenCV** | Image processing library used to enhance and validate KYC documents before hashing. |

### 📱 Front-end & Mobile Development

| Technology | Purpose |
| :--- | :--- |
| **React Native (Expo)** | Cross-platform development for the tourist mobile application. |
| **React / Next.js** | Development of the Authority Real-time Visualization Dashboard. |
| **Nativewind** | Utility-first CSS framework for responsive design and seamless styling in React Native. |

How safety route is calculated ?

Kavach calculates route safety with combined signals:
Street lighting (well-lit → best)
Business density (more businesses → safer)
Population density (more people → safer)

Route data flow
Get origin + destination coordinates (source text geocoding)
Fetch route alternatives from OpenRouteService (driving-car)
Compute route bounds (buffer around origin+destination)
Fetch OSM lighting data in bounds
Fetch OSM business/population proxies in bounds
For each route:
decode polyline into points
apply lighting classification per point
compute density scores near points
combine into final safety score
Sort routes by final score, show top 2

Route data flow
Get origin + destination coordinates (source text geocoding)
Fetch route alternatives from OpenRouteService (driving-car)
Compute route bounds (buffer around origin+destination)
Fetch OSM lighting data in bounds
Fetch OSM business/population proxies in bounds
For each route:
decode polyline into points
apply lighting classification per point
compute density scores near points
combine into final safety score
Sort routes by final score, show top 2

Function: scoreBusinessDensity(points, businessData)

For each route point:
count nearby business points within 70m (shops/restaurants/banks/etc)
Score = (matchedPoints / totalPoints) * 100
0 = none, 100 = all points near business


. Population density score
Function: scorePopulationDensity(points, populationData)

Route points close to residential/urban way segments
Score = (matchedPoints / totalPoints) * 100

6. Composite safety score
Function: combineScores(lighting, business, population)

Weights used:

lighting: 55%
business: 30%
population: 15%

Lighting Source
Source: OpenStreetMap via Overpass API in services/streetLightingService.js

Business
Source: OpenStreetMap via Overpass API in same service (fetchBusinessAndPopulationData)

Population (urban/residential density bucket)
Source: OpenStreetMap via Overpass API in same service function

=======
>>>>>>> 988aef02ba1f42cee312915042df2cc625cfeeeb
