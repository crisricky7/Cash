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
        var isAnnual = request.PlanCode.Contains("annual", StringComparison.OrdinalIgnoreCase);
        var totalCents = isAnnual ? 3999 : 499; // $39.99 o $4.99 en centavos
        var storeId = configuration["Payphone:StoreId"] ?? "STORE_ID_CONFIGURAR_EN_PAYPHONE_DEV";
        var clientTxId = $"CASH-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString()[..6].ToUpper()}";

        // Desglose de impuestos (IVA 15% Ecuador o tarifa 0% según configuración)
        var amountWithoutTax = (int)Math.Round(totalCents / 1.15m);
        var tax = totalCents - amountWithoutTax;

        return new PayphonePrepareResponse(
            ClientTransactionId: clientTxId,
            StoreId: storeId,
            AmountInCents: totalCents,
            AmountWithoutTaxInCents: 0,
            AmountWithTaxInCents: amountWithoutTax,
            TaxInCents: tax,
            Currency: "USD",
            Description: isAnnual ? "Suscripción Anual Cash Pro Familiar" : "Suscripción Mensual Cash Pro Familiar"
        );
    }

    public async Task<PayphoneConfirmResponse> ConfirmTransactionAsync(PayphoneConfirmRequest request, CancellationToken ct = default)
    {
        var token = configuration["Payphone:Token"];

        // Si aún no se ha colocado el token productivo de Payphone Developer, responde en modo Sandbox
        if (string.IsNullOrWhiteSpace(token) || token.StartsWith("PEGAR_AQUI"))
        {
            return new PayphoneConfirmResponse(
                Success: true,
                TransactionStatus: "Approved",
                AuthorizationCode: $"AUTH-SANDBOX-{Random.Shared.Next(100000, 999999)}",
                Message: "Pago confirmado exitosamente (Modo Sandbox listo para credenciales de producción).",
                PlanActivated: request.PlanCode
            );
        }

        // Llamada oficial a Payphone Confirm V2 (Obligatoria antes de 5 minutos para evitar reverso automático)
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
