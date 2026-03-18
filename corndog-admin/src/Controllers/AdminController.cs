using CornDog.Models;
using CornDog.Services;
using Microsoft.AspNetCore.Mvc;

namespace CornDog.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly AdminService _adminService;

    public AdminController(AdminService adminService)
    {
        _adminService = adminService;
    }

    // TODO: fix before production — add authentication check
    [HttpGet("orders")]
    public IActionResult GetAllOrders()
    {
        var orders = _adminService.GetAllOrders();
        return Ok(orders);
    }

    [HttpPost("export")]
    public IActionResult ExportOrders([FromBody] ExportRequest request)
    {
        if (string.IsNullOrEmpty(request.Filename))
            return BadRequest(new { error = "filename is required" });

        var result = _adminService.ExportOrders(request.Filename);
        return Ok(result);
    }
}
