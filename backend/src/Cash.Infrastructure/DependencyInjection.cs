using Cash.Domain.Interfaces;
using Cash.Infrastructure.Persistence;
using Cash.Infrastructure.Repositories;
using Cash.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Cash.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var conn = configuration.GetConnectionString("DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=cash_db;Username=postgres;Password=Password123!";
        services.AddDbContext<CashDbContext>(opt => opt.UseNpgsql(conn));
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddSingleton<IJwtProvider, JwtProvider>();
        return services;
    }
}
