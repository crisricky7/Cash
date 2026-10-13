using Cash.Domain.Entities;
using Cash.Domain.Enums;
using Cash.Domain.Interfaces;

namespace Cash.Api;

public static class CatalogsEndpoints
{
    public static void MapCatalogsCrudEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/catalogs").RequireAuthorization();

        // Crear Cuenta (Banco, Billetera Digital, Efectivo, etc.)
        group.MapPost("/accounts", async (CreateAccountRequest req, IUnitOfWork uow, CancellationToken ct) =>
        {
            var account = new Account
            {
                Name = req.Name.Trim(),
                AccountType = string.IsNullOrWhiteSpace(req.AccountType) ? "Billetera Digital" : req.AccountType.Trim(),
                Balance = req.InitialBalance,
                Currency = string.IsNullOrWhiteSpace(req.Currency) ? "USD" : req.Currency
            };
            await uow.Accounts.AddAsync(account, ct);
            await uow.SaveChangesAsync(ct);
            return Results.Created($"/api/catalogs/accounts/{account.Id}", account);
        });

        // Transferencia o Recarga hacia Billetera Digital (No suma como gasto mensual)
        group.MapPost("/accounts/transfer", async (TransferBalanceRequest req, IUnitOfWork uow, CancellationToken ct) =>
        {
            if (req.Amount <= 0) return Results.BadRequest(new { message = "El monto debe ser mayor a cero." });
            if (req.SourceAccountId == req.DestinationAccountId)
                return Results.BadRequest(new { message = "La cuenta origen y destino deben ser distintas." });

            var source = await uow.Accounts.GetByIdAsync(req.SourceAccountId, ct);
            var dest = await uow.Accounts.GetByIdAsync(req.DestinationAccountId, ct);
            if (source is null || dest is null) return Results.NotFound();

            source.Balance -= req.Amount;
            dest.Balance += req.Amount;

            uow.Accounts.Update(source);
            uow.Accounts.Update(dest);

            await uow.Transactions.AddAsync(new Transaction
            {
                AccountId = source.Id,
                CategoryId = Guid.Empty,
                Amount = req.Amount,
                Type = TransactionType.Transfer,
                Description = $"Transferencia / Recarga: {source.Name} → {dest.Name}",
                MemberName = string.IsNullOrWhiteSpace(req.MemberName) ? "Hogar" : req.MemberName
            }, ct);

            await uow.SaveChangesAsync(ct);
            return Results.Ok(new { sourceBalance = source.Balance, destinationBalance = dest.Balance });
        });

        // Eliminar Cuenta
        group.MapDelete("/accounts/{id:guid}", async (Guid id, IUnitOfWork uow, CancellationToken ct) =>
        {
            var acc = await uow.Accounts.GetByIdAsync(id, ct);
            if (acc is null) return Results.NotFound();
            uow.Accounts.Delete(acc);
            await uow.SaveChangesAsync(ct);
            return Results.NoContent();
        });

        // Crear Categoría de Ingreso o Gasto
        group.MapPost("/categories", async (CreateCategoryRequest req, IUnitOfWork uow, CancellationToken ct) =>
        {
            var category = new Category
            {
                Name = req.Name.Trim(),
                Type = req.Type,
                MonthlyBudget = req.Type == TransactionType.Expense ? req.MonthlyBudget : 0m,
                Icon = string.IsNullOrWhiteSpace(req.Icon) ? "category" : req.Icon
            };
            await uow.Categories.AddAsync(category, ct);
            await uow.SaveChangesAsync(ct);
            return Results.Created($"/api/catalogs/categories/{category.Id}", category);
        });

        // Eliminar Categoría
        group.MapDelete("/categories/{id:guid}", async (Guid id, IUnitOfWork uow, CancellationToken ct) =>
        {
            var cat = await uow.Categories.GetByIdAsync(id, ct);
            if (cat is null) return Results.NotFound();
            uow.Categories.Delete(cat);
            await uow.SaveChangesAsync(ct);
            return Results.NoContent();
        });
    }
}

public record CreateAccountRequest(string Name, string AccountType, decimal InitialBalance, string Currency = "USD");
public record TransferBalanceRequest(Guid SourceAccountId, Guid DestinationAccountId, decimal Amount, string MemberName);
public record CreateCategoryRequest(string Name, TransactionType Type, decimal MonthlyBudget, string Icon = "category");
