using Cash.Application.DTOs;
using Cash.Infrastructure.Payments;
using Microsoft.Extensions.Configuration;

namespace Cash.Api;

public static class BillingEndpoints
{
    public static void MapBillingEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/billing");

        group.MapPost("/payphone/prepare", (PayphonePrepareRequest req, PayphoneGatewayService service) =>
        {
            var res = service.PrepareCheckout(req);
            return Results.Ok(res);
        });

        group.MapPost("/payphone/confirm", async (PayphoneConfirmRequest req, PayphoneGatewayService service, CancellationToken ct) =>
        {
            var res = await service.ConfirmTransactionAsync(req, ct);
            return res.Success ? Results.Ok(res) : Results.BadRequest(res);
        });

        group.MapPost("/revenuecat/webhook", (HttpRequest httpRequest, RevenueCatWebhookPayload payload, IConfiguration config) =>
        {
            var expectedSecret = config["RevenueCat:WebhookSecret"];
            if (!string.IsNullOrWhiteSpace(expectedSecret) && !expectedSecret.StartsWith("CONFIGURAR"))
            {
                var authHeader = httpRequest.Headers.Authorization.ToString();
                if (authHeader != $"Bearer {expectedSecret}")
                    return Results.Unauthorized();
            }

            var evt = payload.Event;
            if (evt is null) return Results.BadRequest(new { message = "Evento vacío" });

            var isProActive = evt.Type is "INITIAL_PURCHASE" or "RENEWAL" or "UNCANCELLATION";

            return Results.Ok(new
            {
                received = true,
                eventType = evt.Type,
                appUserId = evt.App_User_Id,
                store = evt.Store,
                proActive = isProActive
            });
        });

        group.MapPost("/revenuecat/verify", (RevenueCatMobileVerifyRequest req) =>
        {
            return Results.Ok(new
            {
                success = true,
                entitlement = "cash_pro",
                store = req.Store,
                productId = req.ProductId,
                activatedAt = DateTime.UtcNow
            });
        });
    }
}
