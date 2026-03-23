package com.corndog.controller;

import com.corndog.model.MenuItem;
import com.corndog.service.MenuService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/menu")
@CrossOrigin(origins = "*")
public class MenuController {

    private final MenuService menuService;

    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @GetMapping
    public List<MenuItem> getAllItems() {
        return menuService.getAllItems();
    }

    @GetMapping("/{id}")
    public MenuItem getItem(@PathVariable Long id) {
        return menuService.getItem(id);
    }

    @GetMapping("/{id}/formatted")
    public Map<String, String> getFormattedItem(
            @PathVariable Long id,
            @RequestParam(defaultValue = "${name} — ${description} ($${price})") String template) {
        return menuService.formatItem(id, template);
    }
}
