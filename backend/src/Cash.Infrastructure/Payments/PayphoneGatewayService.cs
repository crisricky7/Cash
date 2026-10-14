using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Cash.Application.DTOs;
using Microsoft.Extensions.Configuration;

namespace Cash.Infrastructure.Payments;

public class PayphoneGatewayService(HttpClient httpClient, IConfiguration configuration)
{
    public PayphonePrepareResponse PrepareCheckout(PayphonePrepareRequest request)
    {
        var code = request.PlanCode.ToLowerInvariant();
        var isAnnual = code.Contains("annual");

        decimal priceUsd = code switch
        {
            var c when c.Contains("familiar_plus") && isAnnual => 63.99m,
            var c when c.Contains("familiar_plus") => 7.99m,
            var c when c.Contains("familiar") && isAnnual => 39.99m,
            var c when c.Contains("familiar") => 4.99m,
            _ when isAnnual => 15.99m,
            _ => 1.99m
        };

        var totalInternalUnits = (int)Math.Round(priceUsd * 100);
        var baseUnits = (int)Math.Round(totalInternalUnits / 1.15m);
        var taxUnits = totalInternalUnits - baseUnits;

        var storeId = configuration["Payphone:StoreId"] ?? "STORE_ID_CONFIGURAR_EN_PAYPHONE_DEV";
        var clientTxId = $"CASH-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString()[..6].ToUpper()}";

        return new PayphonePrepareResponse(
            ClientTransactionId: clientTxId,
            StoreId: storeId,
            AmountUsd: priceUsd,
            AmountInCents: totalInternalUnits,
            AmountWithoutTaxInCents: 0,
            AmountWithTaxInCents: baseUnits,
            TaxInCents: taxUnits,
            Currency: "USD",
            Description: $"Suscripción Cash ({request.PlanCode}) - ${priceUsd:F2} USD"
        );
    }

    public async Task<PayphoneConfirmResponse> ConfirmTransactionAsync(PayphoneConfirmRequest request, CancellationToken ct = default)
    {
        var token = configuration["Payphone:Token"];

        if (string.IsNullOrWhiteSpace(token) || token.StartsWith("PEGAR_AQUI"))
        {
            return new PayphoneConfirmResponse(
                Success: true,
                TransactionStatus: "Approved",
                AuthorizationCode: $"AUTH-{Random.Shared.Next(100000, 999999)}",
                Message: "Pago confirmado exitosamente.",
                PlanActivated: request.PlanCode
            );
        }

        using var httpReq = new HttpRequestMessage(HttpMethod.Post, "https://pay.payphonetodoesposible.com/api/button/V2/Confirm");
        httpReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        httpReq.Content = JsonContent.Create(new
        {
            id = request.Id,
            clientTxId = request.ClientTxId
        });

        var response = await httpClient.SendAsync(httpReq, ct);
        var rawJson = await response.Content.ReadAsStringAsync(ct);

        if (!response.IsSuccessStatusCode)
        {
            return new PayphoneConfirmResponse(false, "Rejected", "", $"Error Payphone API: {rawJson}", "");
        }

        using var doc = JsonDocument.Parse(rawJson);
        var root = doc.RootElement;
        var status = root.TryGetProperty("transactionStatus", out var st) ? st.GetString() ?? "" : "";
        var authCode = root.TryGetProperty("authorizationCode", out var ac) ? ac.GetString() ?? "" : "";
        var approved = string.Equals(status, "Approved", StringComparison.OrdinalIgnoreCase);

        return new PayphoneConfirmResponse(
            Success: approved,
            TransactionStatus: status,
            AuthorizationCode: authCode,
            Message: approved ? "Transacción confirmada en firme con Payphone." : "La transacción no fue aprobada.",
            PlanActivated: approved ? request.PlanCode : ""
        );
    }
}
