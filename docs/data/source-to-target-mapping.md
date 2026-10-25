# Source-to-target mapping

| Source | Staging field | Target / rule |
|---|---|---|
| `Pharmacies.Id` | `stg.Pharmacies.Id` | `DimPharmacy.PharmacyKey` |
| `Pharmacies.[Key]` | `stg.Pharmacies.PharmacyBisKey` | `DimPharmacy.PharmacyBisKey`, fact pharmacy lookup |
| `Pharmacies.TestFlag` | `stg.Pharmacies.TestFlag` | `DimPharmacy.TestFlag` (view filter) |
| `OrderStateTypes.Id` | `stg.OrderStateTypes.Id` | `DimOrderStatus.OrderStatusKey` |
| `OrderStateTypes.OrderStateTypeId` | same | `DimOrderStatus.OrderStateTypeId` status lookup |
| `OrderStateTypes.StateName` | same | `Delivered` inclusion rule |
| `Orders.Id` | `stg.Orders.Id` | distinct `TotalOrders` |
| `Orders.PharmacyKey` | `stg.Orders.PharmacyBisKey` | resolve `DimPharmacy.PharmacyKey` |
| `Orders.CreatedOn` | `stg.Orders.CreatedOn` | Monday date, resolve `DimDate.DateKey` |
| `OrderItems.OrderId` | `stg.OrderItems.OrderId` | order-to-items join |
| `OrderItems.Price` | `stg.OrderItems.Price` | weekly sum `Price * Quantity` |
| `OrderItems.Quantity` | `stg.OrderItems.Quantity` | weekly sum `Price * Quantity` |

`TotalSales` excludes delivery fee and refunds unless already represented by item price. Null, negative or zero quantities are rejected; negative price is rejected. Original source values are not preserved if conversion to staging decimal fails; loading errors/rejection prevent publishing the snapshot.
