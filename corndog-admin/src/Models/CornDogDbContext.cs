using Microsoft.EntityFrameworkCore;

namespace CornDog.Models;

public class CornDogDbContext : DbContext
{
    public CornDogDbContext(DbContextOptions<CornDogDbContext> options) : base(options) { }

    public DbSet<Order> Orders { get; set; } = null!;
}
