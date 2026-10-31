using Cash.Application.DTOs;
using Cash.Domain.Enums;
using Cash.Domain.Interfaces;
using MediatR;

namespace Cash.Application.Features.Dashboard.Queries;

public record GetDashboardQuery(int Year, int Month) : IRequest<DashboardDto>;

public class GetDashboardQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetDashboardQuery, DashboardDto>
{
    public async Task<DashboardDto> Handle(GetDashboardQuery request, CancellationToken cancellationToken)
    {
        var accounts = await unitOfWork.Accounts.GetAllAsync(cancellationToken);
        var categories = await unitOfWork.Categories.GetAllAsync(cancellationToken);
        var monthlyTx = await unitOfWork.Transactions.GetByMonthAsync(request.Year, request.Month, cancellationToken);
        var recentTx = await unitOfWork.Transactions.GetRecentWithDetailsAsync(20, cancellationToken);

        var totalBalance = accounts.Sum(a => a.Balance);
        var monthlyIncome = monthlyTx.Where(t => t.Type == TransactionType.Income).Sum(t => t.Amount);
        var monthlyExpense = monthlyTx.Where(t => t.Type == TransactionType.Expense).Sum(t => t.Amount);

        var memberExpenses = monthlyTx
            .Where(t => t.Type == TransactionType.Expense)
            .GroupBy(t => t.MemberName)
            .Select(g => new MemberExpenseSummaryDto(g.Key, g.Sum(x => x.Amount)))
            .OrderByDescending(x => x.TotalSpent)
            .ToList();

        var recentDtos = recentTx.Select(t => new TransactionDto(
            t.Id, t.Description, t.Amount, t.Type,
            t.Category?.Name ?? (t.Type == TransactionType.Transfer ? "Transferencia" : "General"), t.Account?.Name ?? "Cuenta",
            t.MemberName, t.Date)).ToList();

        var budgetDtos = categories
            .Where(c => c.Type == TransactionType.Expense)
            .Select(c => new CategoryBudgetDto(
                c.Id, c.Name, c.MonthlyBudget,
                monthlyTx.Where(t => t.CategoryId == c.Id && t.Type == TransactionType.Expense).Sum(t => t.Amount)
            )).ToList();

        return new DashboardDto(totalBalance, monthlyIncome, monthlyExpense, memberExpenses, recentDtos, budgetDtos);
    }
}
