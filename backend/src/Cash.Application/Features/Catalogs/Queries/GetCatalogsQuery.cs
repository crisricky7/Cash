using Cash.Application.DTOs;
using Cash.Domain.Interfaces;
using MediatR;

namespace Cash.Application.Features.Catalogs.Queries;

public record GetCatalogsQuery() : IRequest<CatalogsDto>;

public class GetCatalogsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetCatalogsQuery, CatalogsDto>
{
    public async Task<CatalogsDto> Handle(GetCatalogsQuery request, CancellationToken cancellationToken)
    {
        var accounts = await unitOfWork.Accounts.GetAllAsync(cancellationToken);
        var categories = await unitOfWork.Categories.GetAllAsync(cancellationToken);

        return new CatalogsDto(
            accounts.Select(a => new AccountItemDto(a.Id, a.Name, a.AccountType, a.Balance)).ToList(),
            categories.Select(c => new CategoryItemDto(c.Id, c.Name, c.Type, c.MonthlyBudget)).ToList()
        );
    }
}
