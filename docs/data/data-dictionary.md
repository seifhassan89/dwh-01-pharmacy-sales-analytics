# Data dictionary

| Object | Column | Type | Meaning |
|---|---|---|---|
| `FactWeeklyPharmacySales` | `WeekStartDateKey` | INT PK/FK | Monday `YYYYMMDD`, references DimDate |
| | `PharmacyKey` | INT PK/FK | Source-derived pharmacy ID |
| | `TotalOrders` | INT | Distinct qualifying Delivered orders (positive) |
| | `TotalSales` | DECIMAL(38,2) | Sum of Price × Quantity across qualifying items |
| `DimDate` | `DateKey` | INT PK | `YYYYMMDD` |
| | `FullDate` | DATE UNIQUE | Calendar day |
| | `WeekOfYear` | TINYINT | ISO week (Year is calendar year, not ISO week-year) |
| `DimPharmacy` | `PharmacyKey` | INT PK | Source Pharmacies.Id |
| | `PharmacyBisKey` | NVARCHAR(200) UNIQUE | Source Pharmacies.[Key] |
| | `TestFlag` | BIT | Excluded only in reporting view |
| `DimOrderStatus` | `OrderStateTypeId` | INT UNIQUE | Business key linked to Orders status |
| | `StateName` | NVARCHAR(200) | Delivered inclusion lookup |
| `vw_WeeklyPharmacySales` | `WeekStart`, `WeekEnd` | DATE | Monday / Sunday |

Staging tables mirror the source entity IDs and keys for the run. They are not historical audit tables.
