using Cash.Domain.Enums;

namespace Cash.Domain.Entities;

public class Category
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = "category";
    public TransactionType Type { get; set; }
    public decimal MonthlyBudget { get; set; }
    public string Bucket503020 { get; set; } = "Necesidades (50%)";
}
