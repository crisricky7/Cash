namespace Cash.Domain.Entities;

public class SavingsGoal
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public decimal TargetAmount { get; set; }
    public decimal CurrentAmount { get; set; }
    public DateTime TargetDate { get; set; }
    public string Icon { get; set; } = "savings";
}
