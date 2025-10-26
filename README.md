# BloodBridge
Here are two clean, strong lines:  **BloodBridge eliminates life-threatening delays by connecting hospitals, blood banks, and eligible donors in real time to locate and secure compatible blood instantly.** **This unified network streamlines requests and responses, ensuring the right blood reaches the right patient when every second matters.**

## 🚨 Problem

Hospitals frequently face critical shortages of compatible blood during emergencies.  
The traditional workflow is slow and fragmented:

- Calls must be made manually to blood banks  
- Inventory information is often outdated  
- Donor networks are not activated quickly enough  

**The result: avoidable delays and preventable loss of life.**

According to the American Red Cross, thousands of lives are lost each year due to delays in accessing compatible blood during urgent situations.

---

## 💡 Solution

**BloodBridge provides a unified digital network** that connects:
| Role | Capabilities |
|-----|--------------|
| **Hospitals** | Request blood instantly based on patient needs |
| **Blood Banks** | Respond to requests, fulfill units, update stock |
| **Eligible Donors** | Receive alerts when their blood type is urgently needed nearby |

The system uses:
- Real-time inventory visibility
- Instant emergency request routing
- Location-based donor notification
- Structured and auditable transaction logging

This reduces emergency response time significantly and increases survival probability.

---

## 🏛 System Overview

BloodBridge is built as a **database-driven Flask web application** with two main layers:

### 1. **Core Schema (Identity Layer)**
Stores master data:
- Hospitals
- Blood banks
- Donors
- Location and contact details
- Blood type and eligibility profile

### 2. **Ops Schema (Operational Layer)**
Handles workflow and time-based events:
- Blood requests
- Fulfillment logs
- Status changes
- Notifications / escalations

A complete SQL export is included in the `db/` folder.

---

## 🗄 Database Setup

To recreate the database:

```sql
CREATE DATABASE bloodbridge;

Then inside psql:
\i db/01_extensions.sql
\i db/03_schema_core.sql
\i db/04_schema_ops.sql
\i db/90_seed_core.sql
\i db/91_seed_ops.sql
