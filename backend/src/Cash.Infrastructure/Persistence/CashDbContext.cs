using System.Security.Cryptography;
using System.Text;
using Cash.Domain.Entities;
using Cash.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Cash.Infrastructure.Persistence;

public class CashDbContext(DbContextOptions<CashDbContext> options) : DbContext(options)
{
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Transaction> Transactions => Set<Transaction>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>(e => { e.HasKey(x => x.Id); e.Property(x => x.Balance).HasColumnType("numeric(18,2)"); });
        modelBuilder.Entity<Category>(e => { e.HasKey(x => x.Id); e.Property(x => x.MonthlyBudget).HasColumnType("numeric(18,2)"); });
        modelBuilder.Entity<User>(e => { e.HasKey(x => x.Id); e.HasIndex(x => x.Email).IsUnique(); });
        modelBuilder.Entity<Transaction>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Amount).HasColumnType("numeric(18,2)");
            e.HasOne(x => x.Account).WithMany().HasForeignKey(x => x.AccountId);
            e.HasOne(x => x.Category).WithMany().HasForeignKey(x => x.CategoryId);
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).IsRequired(false);
        });

        var passHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes("Password123!")));
        modelBuilder.Entity<User>().HasData(
            new User { Id = Guid.Parse("91111111-1111-1111-1111-111111111111"), FullName = "Cristhian (SuperAdmin App)", Email = "admin@cashapp.com", PasswordHash = passHash, Role = "SuperAdmin", CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new User { Id = Guid.Parse("92222222-2222-2222-2222-222222222222"), FullName = "Titular de Cuenta", Email = "usuario@cash.com", PasswordHash = passHash, Role = "Usuario", CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc) }
        );

        modelBuilder.Entity<Account>().HasData(
            new Account { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Name = "Cuenta Bancaria Principal", AccountType = "Banco", Balance = 1850.00m, Currency = "USD", CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new Account { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Name = "Billetera Digital (Payphone / Deuna)", AccountType = "Billetera Digital", Balance = 195.00m, Currency = "USD", CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
            new Account { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Efectivo Disponible", AccountType = "Efectivo", Balance = 140.00m, Currency = "USD", CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc) }
        );

        modelBuilder.Entity<Category>().HasData(
            new Category { Id = Guid.Parse("aaaa1111-1111-1111-1111-111111111111"), Name = "Alimentación y Supermercado", Icon = "shopping_cart", Type = TransactionType.Expense, MonthlyBudget = 600.00m },
            new Category { Id = Guid.Parse("aaaa2222-2222-2222-2222-222222222222"), Name = "Vivienda y Servicios", Icon = "bolt", Type = TransactionType.Expense, MonthlyBudget = 250.00m },
            new Category { Id = Guid.Parse("aaaa3333-3333-3333-3333-333333333333"), Name = "Salud y Educación", Icon = "school", Type = TransactionType.Expense, MonthlyBudget = 300.00m },
            new Category { Id = Guid.Parse("bbbb1111-1111-1111-1111-111111111111"), Name = "Ingresos", Icon = "payments", Type = TransactionType.Income, MonthlyBudget = 0m }
        );
    }
}
