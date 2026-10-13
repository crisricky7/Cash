using System.Linq.Expressions;
using Cash.Domain.Entities;
using Cash.Domain.Interfaces;
using Cash.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cash.Infrastructure.Repositories;

public class Repository<T>(CashDbContext context) : IRepository<T> where T : class
{
    protected readonly CashDbContext _context = context;
    public async Task<T?> GetByIdAsync(Guid id, CancellationToken ct = default) => await _context.Set<T>().FindAsync([id], ct);
    public async Task<IReadOnlyList<T>> GetAllAsync(CancellationToken ct = default) => await _context.Set<T>().AsNoTracking().ToListAsync(ct);
    public async Task<IReadOnlyList<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken ct = default) => await _context.Set<T>().AsNoTracking().Where(predicate).ToListAsync(ct);
    public async Task AddAsync(T entity, CancellationToken ct = default) => await _context.Set<T>().AddAsync(entity, ct);
    public void Update(T entity) => _context.Set<T>().Update(entity);
    public void Delete(T entity) => _context.Set<T>().Remove(entity);
}

public class TransactionRepository(CashDbContext context) : Repository<Transaction>(context), ITransactionRepository
{
    public async Task<IReadOnlyList<Transaction>> GetRecentWithDetailsAsync(int count, CancellationToken ct = default) =>
        await _context.Transactions.AsNoTracking().Include(t => t.Account).Include(t => t.Category).OrderByDescending(t => t.Date).Take(count).ToListAsync(ct);

    public async Task<IReadOnlyList<Transaction>> GetByMonthAsync(int year, int month, CancellationToken ct = default) =>
        await _context.Transactions.AsNoTracking().Where(t => t.Date.Year == year && t.Date.Month == month).ToListAsync(ct);
}

public class UnitOfWork(CashDbContext context) : IUnitOfWork
{
    public IRepository<Account> Accounts { get; } = new Repository<Account>(context);
    public IRepository<Category> Categories { get; } = new Repository<Category>(context);
    public IRepository<User> Users { get; } = new Repository<User>(context);
    public ITransactionRepository Transactions { get; } = new TransactionRepository(context);
    public async Task<int> SaveChangesAsync(CancellationToken ct = default) => await context.SaveChangesAsync(ct);
    public void Dispose() => context.Dispose();
}
