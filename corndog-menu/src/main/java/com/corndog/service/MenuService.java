package com.corndog.service;

import com.corndog.model.MenuItem;
import com.corndog.repository.MenuItemRepository;
import org.apache.commons.text.StringSubstitutor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MenuService {

    private final MenuItemRepository menuItemRepository;

    public MenuService(MenuItemRepository menuItemRepository) {
        this.menuItemRepository = menuItemRepository;
    }

    public List<MenuItem> getAllItems() {
        return menuItemRepository.findAll();
    }

    public List<MenuItem> getItemsByCategory(String category) {
        return menuItemRepository.findByCategoryOrderBySortOrder(category);
    }

    public MenuItem getItem(Long id) {
        return menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found: " + id));
    }

    public Map<String, String> formatItem(Long id, String template) {
        MenuItem item = getItem(id);
        Map<String, Object> values = new HashMap<>();
        values.put("name", item.getName());
        values.put("description", item.getDescription());
        values.put("price", item.getPrice().toString());
        values.put("emoji", item.getEmoji());
        values.put("category", item.getCategory());
        String result = new StringSubstitutor(values).replace(template);
        return Map.of("formatted", result);
    }
}
