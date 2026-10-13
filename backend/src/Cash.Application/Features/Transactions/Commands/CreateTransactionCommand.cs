using Cash.Domain.Entities;
using Cash.Domain.Enums;
using Cash.Domain.Interfaces;
using MediatR;

namespace Cash.Application.Features.Transactions.Commands;

public record CreateTransactionCommand(Guid AccountId, Guid CategoryId, decimal Amount, TransactionType Type, string Description, Guid? UserId, string MemberName) : IRequest<Guid>;

public class CreateTransactionCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateTransactionCommand, Guid>
{
    public async Task<Guid> Handle(CreateTransactionCommand request, CancellationToken cancellationToken)
    {
        var account = await unitOfWork.Accounts.GetByIdAsync(request.AccountId, cancellationToken)
            ?? throw new KeyNotFoundException("La cuenta no existe.");

        var transaction = new Transaction
        {
            AccountId = request.AccountId,
            CategoryId = request.CategoryId,
            UserId = request.UserId,
            Amount = request.Amount,
            Type = request.Type,
            Description = request.Description,
            MemberName = string.IsNullOrWhiteSpace(request.MemberName) ? "Hogar" : request.MemberName,
            Date = DateTime.UtcNow
        };

        account.Balance += request.Type == TransactionType.Income ? request.Amount : -request.Amount;

        await unitOfWork.Transactions.AddAsync(transaction, cancellationToken);
        unitOfWork.Accounts.Update(account);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return transaction.Id;
    }
}
