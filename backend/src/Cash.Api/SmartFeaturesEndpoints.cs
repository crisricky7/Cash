namespace Cash.Api;

public static class SmartFeaturesEndpoints
{
    public static void MapSmartFeaturesEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/smart").RequireAuthorization();

        group.MapPost("/parse-invoice", (InvoiceRawInput req) =>
        {
            var subTotal = Math.Round(req.TotalAmount / 1.15m, 2);
            var iva15 = req.TotalAmount - subTotal;

            var lower = req.MerchantOrRawText.ToLowerInvariant();
            var suggestedCategory = lower.Contains("super") || lower.Contains("maxi")
                ? "Alimentación y Supermercado"
                : lower.Contains("farmacia") || lower.Contains("fybeca") || lower.Contains("salud")
                ? "Salud y Educación"
                : "Vivienda y Servicios";

            return Results.Ok(new
            {
                merchant = req.MerchantOrRawText,
                subTotal,
                taxIva15 = iva15,
                total = req.TotalAmount,
                suggestedCategory
            });
        });
    }
}

public record InvoiceRawInput(string MerchantOrRawText, decimal TotalAmount);
