namespace Cash.Domain.Entities;

public class CreditCardInstallment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string CardName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public int TotalInstallments { get; set; }
    public int PaidInstallments { get; set; }
    public decimal MonthlyQuota => TotalInstallments > 0 ? Math.Round(TotalAmount / TotalInstallments, 2) : 0m;
    public int CutOffDay { get; set; } = 15;
    public int DueDay { get; set; } = 2;
}
