# Model danych RetailDW — przegląd

## Sprzedaż

`dbo.FactSales` — sprzedaż na poziomie linii zamówienia (order line). Wersjonowana
czasowo (system-versioned), historia w `dbo.FactSalesHistory`.

`dbo.FactSalesItem` — szczegóły na poziomie sub-itemu w ramach linii zamówienia.
Zawiera `CustomerKey` powiązany z klientem.

## Klienci

`dbo.DimCustomer` — dane klienta z pełną historią zmian (tier, region).

## Wymiary

`dbo.DimProduct`, `dbo.DimStore` — standardowe wymiary produktowe i sklepowe.

## Raportowanie

`reporting.vw_DailySales`, `reporting.vw_WeeklySales` — agregaty sprzedaży dzienne/
tygodniowe. `reporting.vw_SalesItemRevenue` — przychód na poziomie sub-itemu.
`reporting.usp_SalesSummaryByMonth` — oficjalne miesięczne podsumowanie sprzedaży
dla działu finansowego.
