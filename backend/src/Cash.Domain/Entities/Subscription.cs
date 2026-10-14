namespace Cash.Domain.Entities;

public class Subscription
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string PlanCode { get; set; } = "personal"; // personal | familiar | familiar_plus
    public string BillingCycle { get; set; } = "monthly"; // monthly | annual
    public int MaxUsersAllowed { get; set; } = 1; // 1 | 4 | 7
    public string Provider { get; set; } = string.Empty;
    public string ExternalTransactionId { get; set; } = string.Empty;
    public string ClientTransactionId { get; set; } = string.Empty;
    public decimal AmountUsd { get; set; }
    public string Status { get; set; } = "Active";
    public DateTime StartsAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddMonths(1);
}
