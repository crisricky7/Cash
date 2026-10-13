using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Cash.Domain.Entities;
using Cash.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Cash.Infrastructure.Security;

public class JwtProvider(IConfiguration configuration) : IJwtProvider
{
    public string GenerateToken(User user)
    {
        var secret = configuration["Jwt:Secret"] ?? "CashSuperSecretKeyForHouseholdApp2026!@#";
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim("fullName", user.FullName),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: "Cash.Api",
            audience: "Cash.Mobile",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string HashPassword(string password) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(password)));

    public bool VerifyPassword(string password, string hash) =>
        string.Equals(HashPassword(password), hash, StringComparison.OrdinalIgnoreCase);
}
