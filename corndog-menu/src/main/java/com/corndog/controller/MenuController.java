package com.corndog.controller;

import com.corndog.model.MenuItem;
import com.corndog.service.MenuService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
}
