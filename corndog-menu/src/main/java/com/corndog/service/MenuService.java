package com.corndog.service;

import com.corndog.model.MenuItem;
import com.corndog.repository.MenuItemRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MenuService {

    private final MenuItemRepository menuItemRepository;

    public MenuService(MenuItemRepository menuItemRepository) {
        this.menuItemRepository = menuItemRepository;
    }

    public List<MenuItem> getAllItems() {
        return menuItemRepository.findAll();
    }

    public MenuItem getItem(Long id) {
        return menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found: " + id));
    }
}
