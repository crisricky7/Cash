namespace Cash.Domain.Entities;

public class RecurringBill
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int DueDayOfMonth { get; set; }
    public bool IsPaidThisMonth { get; set; }
}
