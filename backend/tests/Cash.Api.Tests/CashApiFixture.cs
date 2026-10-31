using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc.Testing;
using Testcontainers.PostgreSql;

namespace Cash.Api.Tests;

public sealed class CashApiFixture : IAsyncLifetime
{
    private const string ConnectionVariable = "ConnectionStrings__DefaultConnection";
    private const string JwtVariable = "Jwt__Secret";

    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine").Build();
    private WebApplicationFactory<Program>? _factory;

    public HttpClient Anonymous { get; private set; } = null!;
    public HttpClient Authenticated { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();

        // Program reads its settings while it builds the host, so they must exist before the factory starts it.
        Environment.SetEnvironmentVariable(ConnectionVariable, _postgres.GetConnectionString());
        Environment.SetEnvironmentVariable(JwtVariable, Convert.ToHexString(RandomNumberGenerator.GetBytes(32)));

        _factory = new WebApplicationFactory<Program>();
        Anonymous = _factory.CreateClient();
        Authenticated = _factory.CreateClient();

        var response = await Anonymous.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Alex Demo",
            email = "alex@example.com",
            password = Convert.ToHexString(RandomNumberGenerator.GetBytes(16))
        });
        response.EnsureSuccessStatusCode();
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        Authenticated.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth!.Token);
    }

    public async Task DisposeAsync()
    {
        Anonymous.Dispose();
        Authenticated.Dispose();
        if (_factory is not null) await _factory.DisposeAsync();
        Environment.SetEnvironmentVariable(ConnectionVariable, null);
        Environment.SetEnvironmentVariable(JwtVariable, null);
        await _postgres.DisposeAsync();
    }

    public async Task<Guid> CreateAccountAsync(decimal balance)
    {
        var response = await Authenticated.PostAsJsonAsync("/api/catalogs/accounts", new
        {
            name = $"Test account {Guid.NewGuid():N}",
            accountType = "Banco",
            initialBalance = balance
        });
        response.EnsureSuccessStatusCode();
        var account = await response.Content.ReadFromJsonAsync<CreatedAccount>();
        return account!.Id;
    }

    public async Task<decimal> GetBalanceAsync(Guid accountId)
    {
        var catalogs = await Authenticated.GetFromJsonAsync<CatalogsResponse>("/api/catalogs");
        return catalogs!.Accounts.Single(a => a.Id == accountId).Balance;
    }

    public Task<HttpResponseMessage> TransferAsync(Guid source, Guid destination, decimal amount, HttpClient? client = null) =>
        (client ?? Authenticated).PostAsJsonAsync("/api/catalogs/accounts/transfer", new
        {
            sourceAccountId = source,
            destinationAccountId = destination,
            amount,
            memberName = "Alex Demo"
        });

    private sealed record AuthResponse(string Token);
    private sealed record CreatedAccount(Guid Id);
    private sealed record CatalogsResponse(List<AccountItem> Accounts);
    private sealed record AccountItem(Guid Id, decimal Balance);
}

[CollectionDefinition(Name)]
public sealed class CashApiCollection : ICollectionFixture<CashApiFixture>
{
    public const string Name = "Cash API";
}
