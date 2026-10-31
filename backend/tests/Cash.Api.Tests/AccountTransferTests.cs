using System.Net;
using System.Net.Http.Json;

namespace Cash.Api.Tests;

[Collection(CashApiCollection.Name)]
public class AccountTransferTests(CashApiFixture api)
{
    [Fact]
    public async Task T1_Transfer_updates_both_balances_and_records_the_transaction()
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(10m);

        var response = await api.TransferAsync(source, destination, 25m);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<TransferResponse>();
        Assert.Equal(75m, body!.SourceBalance);
        Assert.Equal(35m, body.DestinationBalance);
        Assert.Equal(75m, await api.GetBalanceAsync(source));
        Assert.Equal(35m, await api.GetBalanceAsync(destination));

        var dashboard = await GetDashboardAsync();
        Assert.Contains(dashboard.RecentTransactions, t => t.Type == TransferType && t.Amount == 25m);
    }

    [Fact]
    public async Task T2_Transfer_does_not_change_dashboard_totals_or_budgets()
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(0m);
        var before = await GetDashboardAsync();

        (await api.TransferAsync(source, destination, 40m)).EnsureSuccessStatusCode();

        var after = await GetDashboardAsync();
        Assert.Equal(before.TotalBalance, after.TotalBalance);
        Assert.Equal(before.MonthlyIncome, after.MonthlyIncome);
        Assert.Equal(before.MonthlyExpense, after.MonthlyExpense);
        Assert.Equal(before.Budgets.Sum(b => b.SpentAmount), after.Budgets.Sum(b => b.SpentAmount));
    }

    [Fact]
    public async Task T3_Transfer_appears_in_recent_transactions_as_Transferencia()
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(0m);

        (await api.TransferAsync(source, destination, 33.33m)).EnsureSuccessStatusCode();

        var dashboard = await GetDashboardAsync();
        var transfer = Assert.Single(dashboard.RecentTransactions, t => t.Amount == 33.33m);
        Assert.Equal("Transferencia", transfer.CategoryName);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-5)]
    public async Task T4_Transfer_rejects_amounts_of_zero_or_less(decimal amount)
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(50m);

        var response = await api.TransferAsync(source, destination, amount);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(100m, await api.GetBalanceAsync(source));
        Assert.Equal(50m, await api.GetBalanceAsync(destination));
    }

    [Fact]
    public async Task T4_Transfer_rejects_the_same_source_and_destination()
    {
        var account = await api.CreateAccountAsync(100m);

        var response = await api.TransferAsync(account, account, 10m);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(100m, await api.GetBalanceAsync(account));
    }

    [Fact]
    public async Task T5_Transfer_returns_not_found_when_an_account_does_not_exist()
    {
        var account = await api.CreateAccountAsync(100m);

        var missingDestination = await api.TransferAsync(account, Guid.NewGuid(), 10m);
        var missingSource = await api.TransferAsync(Guid.NewGuid(), account, 10m);

        Assert.Equal(HttpStatusCode.NotFound, missingDestination.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, missingSource.StatusCode);
        Assert.Equal(100m, await api.GetBalanceAsync(account));
    }

    [Fact]
    public async Task T6_Transfer_requires_a_valid_token()
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(50m);

        var response = await api.TransferAsync(source, destination, 10m, api.Anonymous);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(100m, await api.GetBalanceAsync(source));
        Assert.Equal(50m, await api.GetBalanceAsync(destination));
    }

    [Fact]
    public async Task T7_Transfer_can_leave_the_source_balance_negative()
    {
        var source = await api.CreateAccountAsync(10m);
        var destination = await api.CreateAccountAsync(0m);

        var response = await api.TransferAsync(source, destination, 30m);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(-20m, await api.GetBalanceAsync(source));
        Assert.Equal(30m, await api.GetBalanceAsync(destination));
    }

    private const int TransferType = 3;

    private async Task<DashboardResponse> GetDashboardAsync() =>
        (await api.Authenticated.GetFromJsonAsync<DashboardResponse>("/api/dashboard"))!;

    private sealed record TransferResponse(decimal SourceBalance, decimal DestinationBalance);
    private sealed record DashboardResponse(
        decimal TotalBalance,
        decimal MonthlyIncome,
        decimal MonthlyExpense,
        List<RecentTransaction> RecentTransactions,
        List<Budget> Budgets);
    private sealed record RecentTransaction(decimal Amount, int Type, string CategoryName);
    private sealed record Budget(decimal SpentAmount);
}
