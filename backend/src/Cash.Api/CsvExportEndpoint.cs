using System.Text;
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
                var tipo = t.Type == Cash.Domain.Enums.TransactionType.Income ? "INGRESO" : "GASTO";
                var desc = t.Description.Replace(",", " ");
                var cat = (t.Category?.Name ?? "General").Replace(",", " ");
                var acc = (t.Account?.Name ?? "Cuenta").Replace(",", " ");
                sb.AppendLine($"{t.Date:yyyy-MM-dd},{tipo},{cat},{desc},{acc},{t.MemberName},{t.Amount:F2}");
            }

            var bytes = Encoding.UTF8.GetBytes(sb.ToString());
            return Results.File(bytes, "text/csv", $"Cash_Reporte_{DateTime.UtcNow:yyyyMM}.csv");
        }).RequireAuthorization();
    }
}
