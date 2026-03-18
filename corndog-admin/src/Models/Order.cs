using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CornDog.Models;

[Table("orders")]
public class Order
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("customer_name")]
    public string CustomerName { get; set; } = string.Empty;

    [Column("items", TypeName = "jsonb")]
    public string Items { get; set; } = "[]";

    [Column("special_instructions")]
    public string? SpecialInstructions { get; set; }

    [Column("total_price")]
    public decimal TotalPrice { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
