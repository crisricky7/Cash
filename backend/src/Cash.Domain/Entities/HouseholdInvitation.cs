namespace Cash.Domain.Entities;

public class HouseholdInvitation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid HouseholdOwnerId { get; set; }
    public string InvitedName { get; set; } = string.Empty;
    public string InvitedEmail { get; set; } = string.Empty;
    public string InvitationToken { get; set; } = Guid.NewGuid().ToString("N");
    public string Status { get; set; } = "Pending"; // Pending | Accepted | Expired
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? AcceptedAt { get; set; }
}
