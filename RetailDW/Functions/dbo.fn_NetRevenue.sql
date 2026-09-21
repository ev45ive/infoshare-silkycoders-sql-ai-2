/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Rounds a gross amount to a VAT-exclusive net revenue figure.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE FUNCTION [dbo].[fn_NetRevenue]
(
    @GrossAmount DECIMAL (18, 4),
    @VatRate     DECIMAL (5, 4)
)
RETURNS DECIMAL (18, 4)
AS
BEGIN
    IF @GrossAmount IS NULL OR @VatRate IS NULL
        RETURN NULL;

    RETURN ROUND(@GrossAmount / (1 + @VatRate), 2);
END
