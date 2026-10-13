namespace Cash.Domain.Entities;

public class Subscription
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string PlanCode { get; set; } = "cash_pro_monthly"; // cash_pro_monthly | cash_pro_annual
    public string Provider { get; set; } = string.Empty;       // Payphone | RevenueCat_GooglePlay | RevenueCat_AppStore
    public string ExternalTransactionId { get; set; } = string.Empty;
    public string ClientTransactionId { get; set; } = string.Empty;
    public decimal AmountUsd { get; set; }
    public string Status { get; set; } = "Active";             // Pending | Active | Cancelled | Expired
    public DateTime StartsAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddMonths(1);
}
