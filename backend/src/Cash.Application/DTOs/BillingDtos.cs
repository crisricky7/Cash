namespace Cash.Application.DTOs;

// Payphone DTOs (Montos expresados en centavos según estándar de Payphone)
public record PayphonePrepareRequest(string PlanCode, string UserEmail);

public record PayphonePrepareResponse(
    string ClientTransactionId,
    string StoreId,
    int AmountInCents,
    int AmountWithoutTaxInCents,
    int AmountWithTaxInCents,
    int TaxInCents,
    string Currency,
    string Description);

public record PayphoneConfirmRequest(int Id, string ClientTxId, string PlanCode);

public record PayphoneConfirmResponse(
    bool Success,
    string TransactionStatus,
    string AuthorizationCode,
    string Message,
    string PlanActivated);

// RevenueCat Webhook & Mobile Sync DTOs
public record RevenueCatWebhookPayload(RevenueCatEvent? Event);

public record RevenueCatEvent(
    string Type,
    string App_User_Id,
    string Product_Id,
    string Store,
    long? Expiration_At_Ms,
    string? Transaction_Id);

public record RevenueCatMobileVerifyRequest(
    string AppUserId,
    string ProductId,
    string Store, // PLAY_STORE | APP_STORE
    string ReceiptOrTransactionId);
