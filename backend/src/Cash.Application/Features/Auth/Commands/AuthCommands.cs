using Cash.Application.DTOs;
using Cash.Domain.Entities;
using Cash.Domain.Interfaces;
using MediatR;

namespace Cash.Application.Features.Auth.Commands;

public record LoginCommand(string Email, string Password) : IRequest<AuthResponseDto>;

public class LoginCommandHandler(IUnitOfWork unitOfWork, IJwtProvider jwtProvider)
    : IRequestHandler<LoginCommand, AuthResponseDto>
{
    public async Task<AuthResponseDto> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var users = await unitOfWork.Users.FindAsync(u => u.Email == email, cancellationToken);
        var user = users.FirstOrDefault() ?? throw new UnauthorizedAccessException("Credenciales inválidas.");

        if (!jwtProvider.VerifyPassword(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Credenciales inválidas.");

        return new AuthResponseDto(user.Id, user.FullName, user.Email, user.Role, jwtProvider.GenerateToken(user));
    }
}

public record RegisterMemberCommand(string FullName, string Email, string Password, string Role = "Usuario") : IRequest<AuthResponseDto>;

public class RegisterMemberCommandHandler(IUnitOfWork unitOfWork, IJwtProvider jwtProvider)
    : IRequestHandler<RegisterMemberCommand, AuthResponseDto>
{
    public async Task<AuthResponseDto> Handle(RegisterMemberCommand request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var existing = await unitOfWork.Users.FindAsync(u => u.Email == email, cancellationToken);
        if (existing.Any()) throw new InvalidOperationException("El correo ya está registrado.");

        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = email,
            PasswordHash = jwtProvider.HashPassword(request.Password),
            Role = string.IsNullOrWhiteSpace(request.Role) ? "Usuario" : request.Role
        };

        await unitOfWork.Users.AddAsync(user, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return new AuthResponseDto(user.Id, user.FullName, user.Email, user.Role, jwtProvider.GenerateToken(user));
    }
}
