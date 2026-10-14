using Cash.Domain.Enums;

namespace Cash.Domain.Entities;

public class Transaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid AccountId { get; set; }
    public Account? Account { get; set; }
    public Guid CategoryId { get; set; }
    public Category? Category { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public decimal Amount { get; set; }
    public TransactionType Type { get; set; }
    public string Description { get; set; } = string.Empty;
    public string MemberName { get; set; } = "Titular";
    public DateTime Date { get; set; } = DateTime.UtcNow;
}
