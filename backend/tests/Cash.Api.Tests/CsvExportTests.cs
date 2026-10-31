using System.Globalization;
using System.Net.Http.Json;

namespace Cash.Api.Tests;

[Collection(CashApiCollection.Name)]
public class CsvExportTests(CashApiFixture api)
{
    private static readonly Guid GroceriesCategory = Guid.Parse("aaaa1111-1111-1111-1111-111111111111");

    [Theory]
    [InlineData("Lunch, office", "\"Lunch, office\"")]
    [InlineData("The \"big\" shop", "\"The \"\"big\"\" shop\"")]
    [InlineData("First line\nSecond line", "\"First line\nSecond line\"")]
    [InlineData("First line\rSecond line", "\"First line\rSecond line\"")]
    public async Task C1_Fields_with_special_characters_are_quoted(string description, string expected)
    {
        await CreateExpenseAsync(description, 1m);

        var csv = await ExportAsync();

        Assert.Contains($",{expected},", csv);
    }

    [Fact]
    public async Task C2_Fields_without_special_characters_are_unchanged()
    {
        await CreateExpenseAsync("Plain description", 1m);

        var csv = await ExportAsync();

        Assert.Contains(",Plain description,", csv);
        Assert.DoesNotContain("\"Plain description\"", csv);
    }

    [Fact]
    public async Task C3_Transfers_are_labelled_TRANSFERENCIA()
    {
        var source = await api.CreateAccountAsync(100m);
        var destination = await api.CreateAccountAsync(0m);
        (await api.TransferAsync(source, destination, 77.77m)).EnsureSuccessStatusCode();

        var csv = await ExportAsync();

        var row = Assert.Single(csv.Split('\n'), line => line.TrimEnd('\r').EndsWith(",77.77"));
        Assert.Contains(",TRANSFERENCIA,", row);
    }

    [Fact]
    public async Task C4_Amounts_use_a_dot_in_any_server_locale()
    {
        var previous = CultureInfo.DefaultThreadCurrentCulture;
        CultureInfo.DefaultThreadCurrentCulture = new CultureInfo("es-ES");
        try
        {
            await CreateExpenseAsync("Locale check", 12.5m);

            var csv = await ExportAsync();

            var row = Assert.Single(csv.Split('\n'), line => line.Contains("Locale check"));
            Assert.EndsWith(",12.50", row.TrimEnd('\r'));
        }
        finally
        {
            CultureInfo.DefaultThreadCurrentCulture = previous;
        }
    }

    private async Task CreateExpenseAsync(string description, decimal amount)
    {
        var account = await api.CreateAccountAsync(100m);
        var response = await api.Authenticated.PostAsJsonAsync("/api/transactions", new
        {
            accountId = account,
            categoryId = GroceriesCategory,
            amount,
            type = 2,
            description
        });
        response.EnsureSuccessStatusCode();
    }

    private Task<string> ExportAsync() => api.Authenticated.GetStringAsync("/api/reports/export-csv");
}
