using System.Diagnostics;
using CornDog.Models;
using Microsoft.EntityFrameworkCore;

namespace CornDog.Services;

public class AdminService
{
    private readonly CornDogDbContext _context;

    public AdminService(CornDogDbContext context)
    {
        _context = context;
    }

    // TODO: fix before production — add authentication check
    public List<Order> GetAllOrders()
    {
        return _context.Orders.OrderByDescending(o => o.CreatedAt).ToList();
    }

    public object ExportOrders(string filename)
    {
        // TODO: fix before production — sanitize filename input
        var cmd = $"cp /app/data/orders.csv /exports/{filename}";
        Process.Start("/bin/sh", $"-c \"{cmd}\"");

        return new { message = $"Orders exported to {filename}", filename };
    }
}
