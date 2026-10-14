using System.Security.Claims;
using System.Text;
using Cash.Api;
using Cash.Application;
using Cash.Application.Features.Auth.Commands;
using Cash.Application.Features.Catalogs.Queries;
using Cash.Application.Features.Dashboard.Queries;
using Cash.Application.Features.Transactions.Commands;
using Cash.Domain.Enums;
using Cash.Infrastructure;
using Cash.Infrastructure.Payments;
using Cash.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddHttpClient<PayphoneGatewayService>();
builder.Services.AddCors(opt => opt.AddPolicy("AllowAll", p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "CashSuperSecretKeyForHouseholdApp2026!@#";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true, ValidateIssuerSigningKey = true,
            ValidIssuer = "Cash.Api", ValidAudience = "Cash.Mobile",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret))
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<CashDbContext>();
    await db.Database.EnsureCreatedAsync();
}

var api = app.MapGroup("/api");

api.MapPost("/auth/login", async (LoginCommand cmd, ISender sender) =>
{
    try { return Results.Ok(await sender.Send(cmd)); }
    catch (UnauthorizedAccessException ex) { return Results.Problem(ex.Message, statusCode: 401); }
});

api.MapPost("/auth/register", async (RegisterMemberCommand cmd, ISender sender) => Results.Ok(await sender.Send(cmd)));

var protectedApi = api.MapGroup("").RequireAuthorization();

protectedApi.MapGet("/dashboard", async (int? year, int? month, ISender sender) =>
{
    var now = DateTime.UtcNow;
    return Results.Ok(await sender.Send(new GetDashboardQuery(year ?? now.Year, month ?? now.Month)));
});

protectedApi.MapGet("/catalogs", async (ISender sender) => Results.Ok(await sender.Send(new GetCatalogsQuery())));

protectedApi.MapPost("/transactions", async (CreateTransactionRequest req, ClaimsPrincipal user, ISender sender) =>
{
    var userIdStr = user.FindFirstValue(ClaimTypes.NameIdentifier);
    var fullName = user.FindFirstValue("fullName") ?? "Titular";
    Guid? userId = Guid.TryParse(userIdStr, out var parsed) ? parsed : null;
    var id = await sender.Send(new CreateTransactionCommand(req.AccountId, req.CategoryId, req.Amount, req.Type, req.Description, userId, fullName));
    return Results.Created($"/api/transactions/{id}", new { id });
});

app.MapExportEndpoints();
app.MapBillingEndpoints();
app.MapCatalogsCrudEndpoints();
app.MapFamilyAndStoriesEndpoints();

app.Run();

public record CreateTransactionRequest(Guid AccountId, Guid CategoryId, decimal Amount, TransactionType Type, string Description);
