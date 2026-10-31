using System.Globalization;
using System.Text;
using Cash.Domain.Enums;
using Cash.Domain.Interfaces;

namespace Cash.Api;

public static class CsvExportEndpoint
{
    public static void MapExportEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/reports/export-csv", async (IUnitOfWork uow, CancellationToken ct) =>
        {
            var txList = await uow.Transactions.GetRecentWithDetailsAsync(500, ct);
            var sb = new StringBuilder();
            sb.AppendLine("Fecha,Tipo,Categoria,Descripcion,Cuenta,Miembro,Monto_USD");

            foreach (var t in txList)
            {
                var tipo = t.Type switch
                {
                    TransactionType.Income => "INGRESO",
                    TransactionType.Transfer => "TRANSFERENCIA",
                    _ => "GASTO"
                };
                var fecha = t.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                var monto = t.Amount.ToString("F2", CultureInfo.InvariantCulture);
                sb.AppendLine($"{fecha},{tipo},{EscapeField(t.Category?.Name)},{EscapeField(t.Description)},{EscapeField(t.Account?.Name)},{EscapeField(t.MemberName)},{monto}");
            }

            return Results.File(Encoding.UTF8.GetBytes(sb.ToString()), "text/csv", "Cash_Reporte.csv");
        }).RequireAuthorization();
    }

    private static string EscapeField(string? value)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;
        return value.IndexOfAny([',', '"', '\n', '\r']) >= 0
            ? $"\"{value.Replace("\"", "\"\"")}\""
            : value;
    }
}
