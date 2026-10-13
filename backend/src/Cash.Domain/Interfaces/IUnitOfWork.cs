using System.Linq.Expressions;
using Cash.Domain.Entities;

namespace Cash.Domain.Interfaces;

public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
    void Update(T entity);
    void Delete(T entity);
}

public interface ITransactionRepository : IRepository<Transaction>
{
    Task<IReadOnlyList<Transaction>> GetRecentWithDetailsAsync(int count, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Transaction>> GetByMonthAsync(int year, int month, CancellationToken cancellationToken = default);
}

public interface IJwtProvider
{
    string GenerateToken(User user);
    string HashPassword(string password);
    bool VerifyPassword(string password, string hash);
}

public interface IUnitOfWork : IDisposable
{
    IRepository<Account> Accounts { get; }
    IRepository<Category> Categories { get; }
    IRepository<User> Users { get; }
    ITransactionRepository Transactions { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
