

# 🏥 Healthcare Admissions Analytics

**PostgreSQL + Dimensional Modeling + Power BI**

## 📌 Project Overview

![Dashboard Overview](Image/Admission%20Analysis.gif)

This project analyzes hospital admissions data to generate operational, clinical, and financial insights using a full data pipeline:

> **Kaggle Dataset → PostgreSQL (Staging) → Dimensional Modeling → Fact Table → Power BI Dashboard**

The objective was to simulate a real-world healthcare analytics workflow, transforming raw hospital admission data into a structured star schema and delivering executive-level insights through interactive BI dashboards.

---

# 🛠 Tech Stack

* **PostgreSQL** – Data cleaning, transformation, and dimensional modeling
* **SQL** – ETL logic and star schema construction
* **Power BI** – Data modeling, DAX measures, and dashboard visualization
* **DAX** – KPI calculations and analytical metrics

---

# 🏗 Data Engineering Workflow

## 1️⃣ Data Ingestion

* Raw dataset downloaded from Kaggle
* Loaded into PostgreSQL staging table
* Data cleaned and validated (null handling, duplicates, type corrections)

## 2️⃣ Dimensional Modeling

A **star schema** was created for scalable analytics.

### Fact Table

`fact_admissions`

* admission_id
* patient_id
* hospital_id
* room_id
* condition_id
* insurance_id
* admission_date_id
* discharge_date_id
* length_of_stay
* billing_amount

### Dimension Tables

* `dim_hospital`
* `dim_room`
* `dim_condition`
* `dim_insurance`
* `dim_admission_type`
* `dim_date`
* `dim_patient`

Grain of the fact table:

> One row per admission event

This ensures accurate aggregation and KPI calculation.

---

# 📊 Dashboard Pages & KPIs

## 🏢 Executive Overview

Key KPIs:

* Total Admissions
* Average Length of Stay (LOS)
* Total Revenue
* Revenue per Admission

Analyses:

* Admission trend by month
* Revenue trend
* Revenue by hospital
* Revenue by medical condition
* Insurance revenue contribution

---

## 🛏 Capacity & Utilization

Operational metrics:

* Admissions per Room
* Room Turnover
* Readmission Rate
* Average Daily Census

Additional analyses:

* Room utilization comparison
* Condition-level readmission rate
* Admission type distribution

> ⚠ Note: The dataset does not include real bed capacity.
> Capacity metrics are calculated using room count as a proxy (1 room = 1 bed).
> This limitation is documented for analytical transparency.

---

## 💰 Financial Analysis

* Revenue by condition
* Revenue by hospital
* Insurance revenue contribution
* LOS vs Revenue scatter analysis
* Revenue per LOS (case intensity proxy)

This connects:

> Clinical metrics ↔ Operational performance ↔ Financial outcomes

---

# 📐 Key DAX Measures

### Total Admissions

```DAX
Total Admissions = COUNT(fact_admissions[admission_id])
```

### Average LOS

```DAX
Average LOS = AVERAGE(fact_admissions[length_of_stay])
```

### Revenue per Admission

```DAX
Revenue per Admission =
DIVIDE([Total Revenue], [Total Admissions], 0)
```

### Readmission Rate

```DAX
Number of Patients with >1 Admission =
COUNTROWS(
    FILTER(
        VALUES(fact_admissions[patient_id]),
        CALCULATE(COUNT(fact_admissions[admission_id])) > 1
    )
)

Readmission Rate =
DIVIDE(
    [Number of Patients with >1 Admission],
    DISTINCTCOUNT(fact_admissions[patient_id]),
    0
)
```

### Average Daily Census

```DAX
Average Daily Census =
DIVIDE(
    SUM(fact_admissions[length_of_stay]),
    DISTINCTCOUNT(dim_date[date]),
    0
)
```

---

# 🔍 Analytical Insights

* Conditions such as Obesity and Diabetes generate the highest total revenue.
* Average LOS remains relatively stable across conditions.
* Readmission rate is approximately 19%, highlighting potential care coordination opportunities.
* Insurance revenue contribution is evenly distributed across providers.
* Revenue per LOS (~$2K) provides a proxy for case intensity.

---

# 📈 What This Project Demonstrates

* End-to-end data pipeline design
* SQL-based ETL and transformation
* Star schema modeling
* DAX-based KPI engineering
* Healthcare-specific performance metrics
* Executive-level dashboard design
* Analytical transparency (capacity limitations documented)

---

# Project Access
Click [here](Healthcare_Admission_Analysis/Project_File/ ) to download the project as pbix file and open with Power BI.

---

# 🚀 Future Improvements

* Implement 30-day readmission logic
* Add mortality rate (if data available)
* Introduce realistic bed-capacity modeling
* Add cost data for margin analysis
* Implement cohort analysis by condition

---

# 🎯 Target Role Alignment

This project aligns with roles such as:

* Healthcare Data Analyst
* Clinical Operations Analyst
* Healthcare BI Developer
* Healthcare Business Intelligence Analyst

--- 

# 📌 Author

**Johnfinnian Nnaemeka**
Healthcare-focused Data Analyst
SQL | PostgreSQL | Power BI | Healthcare Analytics