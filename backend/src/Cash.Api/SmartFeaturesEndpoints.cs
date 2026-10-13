namespace Cash.Api;

public static class SmartFeaturesEndpoints
{
    public static void MapSmartFeaturesEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/smart").RequireAuthorization();

        // Analizador inteligente de facturas electrónicas / recibos (XML / Texto OCR)
        group.MapPost("/parse-invoice", (InvoiceRawInput req) =>
        {
            var subTotal = Math.Round(req.TotalAmount / 1.15m, 2);
            var iva15 = req.TotalAmount - subTotal;

            var lower = req.MerchantOrRawText.ToLowerInvariant();
            var suggestedCategory = lower.Contains("super") || lower.Contains("maxi") || lower.Contains("tia")
                ? "Supermercado y Alimentación"
                : lower.Contains("farmacia") || lower.Contains("fybeca") || lower.Contains("salud") || lower.Contains("med")
                ? "Salud y Bienestar"
                : lower.Contains("colegio") || lower.Contains("univ") || lower.Contains("libro")
                ? "Educación y Hogar"
                : "Servicios Básicos (Luz/Agua/Net)";

            var taxDeductibleGroup = suggestedCategory switch
            {
                "Supermercado y Alimentación" => "Alimentación (Deducible)",
                "Salud y Bienestar" => "Salud (Deducible)",
                "Educación y Hogar" => "Educación, Arte y Cultura (Deducible)",
                _ => "Vivienda y Servicios Básicos (Deducible)"
            };

            return Results.Ok(new
            {
                merchant = req.MerchantOrRawText,
                subTotal,
                taxIva15 = iva15,
                total = req.TotalAmount,
                suggestedCategory,
                taxDeductibleGroup
            });
        });
    }
}

public record InvoiceRawInput(string MerchantOrRawText, decimal TotalAmount);
