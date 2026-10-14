using Cash.Domain.Enums;

namespace Cash.Application.DTOs;

public record AuthResponseDto(Guid UserId, string FullName, string Email, string Role, string Token);
public record MemberExpenseSummaryDto(string MemberName, decimal TotalSpent);
public record TransactionDto(Guid Id, string Description, decimal Amount, TransactionType Type, string CategoryName, string AccountName, string MemberName, DateTime Date);
public record CategoryBudgetDto(Guid CategoryId, string CategoryName, decimal MonthlyBudget, decimal SpentAmount);
public record DashboardDto(decimal TotalBalance, decimal MonthlyIncome, decimal MonthlyExpense, IReadOnlyList<MemberExpenseSummaryDto> MemberExpenses, IReadOnlyList<TransactionDto> RecentTransactions, IReadOnlyList<CategoryBudgetDto> Budgets);
public record CatalogsDto(IReadOnlyList<AccountItemDto> Accounts, IReadOnlyList<CategoryItemDto> Categories);
public record AccountItemDto(Guid Id, string Name, string AccountType, decimal Balance);
public record CategoryItemDto(Guid Id, string Name, TransactionType Type, decimal MonthlyBudget);
