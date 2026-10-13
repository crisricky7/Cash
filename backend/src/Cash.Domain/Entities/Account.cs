namespace Cash.Domain.Entities;

public class Account
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string AccountType { get; set; } = "Banco"; // Banco | Billetera Digital | Efectivo | Tarjeta de Crédito | Ahorro | Cooperativa
    public decimal Balance { get; set; }
    public string Currency { get; set; } = "USD";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
